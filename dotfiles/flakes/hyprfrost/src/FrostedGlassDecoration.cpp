// ─── FrostedGlassDecoration.cpp ──────────────────────────────────────────────

#include "FrostedGlassDecoration.hpp"
#include "globals.hpp"
#include "shaders.hpp"

// Hyprland internals we need
#include <hyprland/src/Compositor.hpp>          // g_pCompositor
#include <hyprland/src/render/OpenGL.hpp>        // g_pHyprOpenGL
#include <hyprland/src/helpers/Monitor.hpp>      // CMonitor
#include <hyprland/src/desktop/Window.hpp>       // CWindow

#include <GLES3/gl32.h>
#include <cstring>   // std::memcpy

// ─────────────────────────────────────────────────────────────────────────────
// Helpers for reading cached config pointers (fast path, no std::any overhead)
// ─────────────────────────────────────────────────────────────────────────────
#define CFG(key) (*(Hyprlang::FLOAT* const*)HyprlandAPI::getConfigValue(PHANDLE, key)->getDataStaticPtr())
#define CFGI(key) (*(Hyprlang::INT*   const*)HyprlandAPI::getConfigValue(PHANDLE, key)->getDataStaticPtr())

// ─────────────────────────────────────────────────────────────────────────────
CFrostedGlassDecoration::CFrostedGlassDecoration(PHLWINDOW pWindow)
    : IHyprWindowDecoration(pWindow), m_pWindow(pWindow) {}

// ─────────────────────────────────────────────────────────────────────────────
CFrostedGlassDecoration::~CFrostedGlassDecoration() {
    destroyGL();
}

// ── IHyprWindowDecoration interface ──────────────────────────────────────────

SDecorationPositioningInfo CFrostedGlassDecoration::getPositioningInfo() {
    // We don't consume any edge – we simply overlay the window's main surface.
    return SDecorationPositioningInfo{
        .policy          = DECORATION_POSITION_STICKY,
        .edges           = 0,
        .desiredExtents  = {},   // zero-init: no edge space claimed
        .priority        = 9000,  // high number = low priority → drawn last in UNDER layer
        .reserved        = false,
    };
}

void CFrostedGlassDecoration::onPositioningReply(const SDecorationPositioningReply& reply) {
    m_assignedBox = reply.assignedGeometry;
}

eDecorationType CFrostedGlassDecoration::getDecorationType() {
    return DECORATION_CUSTOM;
}

eDecorationLayer CFrostedGlassDecoration::getDecorationLayer() {
    // UNDER → renders after Hyprland's blur pass, before the window surface.
    return DECORATION_LAYER_UNDER;
}

uint64_t CFrostedGlassDecoration::getDecorationFlags() {
    // DECORATION_PART_OF_MAIN_WINDOW so it gets clipped/rounded together with
    // the window corners.
    return DECORATION_PART_OF_MAIN_WINDOW;
}

std::string CFrostedGlassDecoration::getDisplayName() {
    return "Hyprfrost Frosted Glass";
}

void CFrostedGlassDecoration::updateRenderData() {
    // Nothing to pre-compute per-frame outside of draw().
}

// ── draw ─────────────────────────────────────────────────────────────────────
void CFrostedGlassDecoration::draw(PHLMONITOR pMonitor, float const& renderRatio) {
    auto pWindow = m_pWindow.lock();
    // m_bIsMapped is sufficient; isHidden() may not exist in all versions.
    if (!pWindow || !pWindow->m_bIsMapped || pWindow->m_bHidden)
        return;

    // ── Read config values (cached static pointers → zero-overhead) ──────────
    static auto const* ENABLED      = CFGI("plugin:hyprfrost:enabled");
    static auto const* TINT_R       = CFG ("plugin:hyprfrost:tint_r");
    static auto const* TINT_G       = CFG ("plugin:hyprfrost:tint_g");
    static auto const* TINT_B       = CFG ("plugin:hyprfrost:tint_b");
    static auto const* TINT_A       = CFG ("plugin:hyprfrost:tint_alpha");
    static auto const* NOISE_AMOUNT = CFG ("plugin:hyprfrost:noise_amount");
    static auto const* NOISE_SCALE  = CFG ("plugin:hyprfrost:noise_scale");
    static auto const* ROUNDING     = CFGI("plugin:hyprfrost:rounding");

    if (!*ENABLED)
        return;

    // ── Geometry ──────────────────────────────────────────────────────────────
    // The window's main-surface box in global compositor space.
    CBox wb = pWindow->getWindowMainSurfaceBox();
    // Translate to monitor-local coords, then scale for HiDPI.
    wb.translate(-pMonitor->vecPosition);
    wb.scale(renderRatio);
    wb.round();

    // ── 1. Tinted glass rect ──────────────────────────────────────────────────
    // Blending is GL_SRC_ALPHA / GL_ONE_MINUS_SRC_ALPHA (Hyprland default).
    // Rendering a coloured rect with alpha < 1 tints the blurred background.
    CHyprColor tint{*TINT_R, *TINT_G, *TINT_B, *TINT_A};
    g_pHyprOpenGL->renderRect(&wb, tint, static_cast<int>(*ROUNDING));

    // ── 2. Frost / grain overlay ──────────────────────────────────────────────
    if (*NOISE_AMOUNT > 0.001f && initGL()) {
        renderNoise(wb, pMonitor, *NOISE_AMOUNT, *NOISE_SCALE, *TINT_A);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// renderNoise
// ─────────────────────────────────────────────────────────────────────────────
void CFrostedGlassDecoration::renderNoise(
        const CBox& box, PHLMONITOR pMonitor,
        float noiseAmount, float noiseScale, float opacity) {

    // Monitor pixel dimensions (used to map clip-space ↔ screen coords).
    const float mW = static_cast<float>(pMonitor->vecPixelSize.x);
    const float mH = static_cast<float>(pMonitor->vecPixelSize.y);

    // Box edges in clip space (y is flipped: OpenGL origin is bottom-left).
    const float x0 =  (box.x           / mW) * 2.0f - 1.0f;
    const float x1 =  ((box.x + box.w) / mW) * 2.0f - 1.0f;
    const float y0 = -((box.y           / mH) * 2.0f - 1.0f);
    const float y1 = -((box.y + box.h) / mH) * 2.0f + 1.0f;

    // Screen-space pixel coords for noise seeding.
    const float sx0 = box.x;
    const float sx1 = box.x + box.w;
    const float sy0 = box.y;
    const float sy1 = box.y + box.h;

    // Interleaved: clipX, clipY, screenX, screenY
    const float verts[4][4] = {
        { x0, y0,  sx0, sy0 },   // bottom-left
        { x1, y0,  sx1, sy0 },   // bottom-right
        { x0, y1,  sx0, sy1 },   // top-left
        { x1, y1,  sx1, sy1 },   // top-right
    };

    // Upload quad vertices directly (no separate stub helper needed)
    glBindVertexArray(m_vao);
    glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(verts), verts, GL_DYNAMIC_DRAW);

    glUseProgram(m_prog);
    glUniform1f(m_uNoiseAmount, noiseAmount);
    glUniform1f(m_uNoiseScale,  noiseScale);
    glUniform1f(m_uOpacity,     opacity);

    // Additive blend: the grain brightens/darkens the glass without covering it.
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glBindVertexArray(0);
    glUseProgram(0);
}

// ─────────────────────────────────────────────────────────────────────────────
// GL initialisation (lazy – called on first draw inside a valid GL context)
// ─────────────────────────────────────────────────────────────────────────────
bool CFrostedGlassDecoration::initGL() {
    if (m_glReady)
        return true;

    // ── Compile shaders ───────────────────────────────────────────────────────
    GLuint vert = compileShader(GL_VERTEX_SHADER,   HYPRFROST_VERT);
    GLuint frag = compileShader(GL_FRAGMENT_SHADER, HYPRFROST_FRAG);

    if (!vert || !frag) {
        glDeleteShader(vert);
        glDeleteShader(frag);
        return false;
    }

    // ── Link program ──────────────────────────────────────────────────────────
    m_prog = glCreateProgram();
    glAttachShader(m_prog, vert);
    glAttachShader(m_prog, frag);

    // Bind attribute locations before linking
    glBindAttribLocation(m_prog, 0, "a_clipPos");
    glBindAttribLocation(m_prog, 1, "a_screenPos");

    glLinkProgram(m_prog);
    glDeleteShader(vert);
    glDeleteShader(frag);

    GLint ok = 0;
    glGetProgramiv(m_prog, GL_LINK_STATUS, &ok);
    if (!ok) {
        char log[512];
        glGetProgramInfoLog(m_prog, sizeof(log), nullptr, log);
        // Log to Hyprland's debug output
        HyprlandAPI::addNotification(PHANDLE,
            std::string("[hyprfrost] shader link error: ") + log,
            CHyprColor{1.f, 0.2f, 0.2f, 1.f}, 8000);
        glDeleteProgram(m_prog);
        m_prog = 0;
        return false;
    }

    // Cache uniform locations
    m_uNoiseAmount = glGetUniformLocation(m_prog, "u_noiseAmount");
    m_uNoiseScale  = glGetUniformLocation(m_prog, "u_noiseScale");
    m_uOpacity     = glGetUniformLocation(m_prog, "u_opacity");

    // ── VAO / VBO ─────────────────────────────────────────────────────────────
    glGenVertexArrays(1, &m_vao);
    glGenBuffers(1, &m_vbo);

    glBindVertexArray(m_vao);
    glBindBuffer(GL_ARRAY_BUFFER, m_vbo);

    // Allocate buffer space (4 vertices × 4 floats each)
    glBufferData(GL_ARRAY_BUFFER, 4 * 4 * sizeof(float), nullptr, GL_DYNAMIC_DRAW);

    // Attribute 0 – clip-space position (xy)
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float),
                          reinterpret_cast<void*>(0));
    // Attribute 1 – screen-space position (xy)
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float),
                          reinterpret_cast<void*>(2 * sizeof(float)));

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    m_glReady = true;
    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
GLuint CFrostedGlassDecoration::compileShader(GLenum type, const std::string& src) {
    GLuint s = glCreateShader(type);
    const char* cstr = src.c_str();
    glShaderSource(s, 1, &cstr, nullptr);
    glCompileShader(s);

    GLint ok = 0;
    glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char log[512];
        glGetShaderInfoLog(s, sizeof(log), nullptr, log);
        HyprlandAPI::addNotification(PHANDLE,
            std::string("[hyprfrost] shader compile error: ") + log,
            CHyprColor{1.f, 0.2f, 0.2f, 1.f}, 8000);
        glDeleteShader(s);
        return 0;
    }
    return s;
}

// ─────────────────────────────────────────────────────────────────────────────
void CFrostedGlassDecoration::destroyGL() {
    if (m_vao) { glDeleteVertexArrays(1, &m_vao); m_vao = 0; }
    if (m_vbo) { glDeleteBuffers(1, &m_vbo);      m_vbo = 0; }
    if (m_prog){ glDeleteProgram(m_prog);          m_prog = 0; }
    m_glReady = false;
}
