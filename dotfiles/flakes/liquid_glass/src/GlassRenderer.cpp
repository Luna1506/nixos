#include "GlassRenderer.hpp"
#include "ShaderSources.hpp"  // auto-generiert via CMake

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/helpers/Box.hpp>

#include <GLES3/gl32.h>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <stdexcept>
#include <vector>
#include <random>
#include <chrono>

// ── Konstruktor / Destruktor ──────────────────────────────────────────────────

CGlassRenderer::CGlassRenderer()  = default;

CGlassRenderer::~CGlassRenderer() {
    if (m_program)  glDeleteProgram(m_program);
    if (m_vao)      glDeleteVertexArrays(1, &m_vao);
    if (m_vbo)      glDeleteBuffers(1, &m_vbo);
    if (m_noiseTex) glDeleteTextures(1, &m_noiseTex);
}

// ── Initialisierung ───────────────────────────────────────────────────────────

bool CGlassRenderer::init() {
    if (!compileShaders())   return false;
    if (!linkProgram())      return false;

    // Uniforms cachen
    auto& u = m_uniforms;
    u.tex           = glGetUniformLocation(m_program, "tex");
    u.texNoise      = glGetUniformLocation(m_program, "texNoise");
    u.resolution    = glGetUniformLocation(m_program, "resolution");
    u.time          = glGetUniformLocation(m_program, "time");
    u.radius        = glGetUniformLocation(m_program, "radius");
    u.blurStrength  = glGetUniformLocation(m_program, "blurStrength");
    u.refractionStr = glGetUniformLocation(m_program, "refractionStrength");
    u.opacity       = glGetUniformLocation(m_program, "opacity");
    u.tintColor     = glGetUniformLocation(m_program, "tintColor");
    u.windowPos     = glGetUniformLocation(m_program, "windowPos");
    u.windowSize    = glGetUniformLocation(m_program, "windowSize");
    u.proj          = glGetUniformLocation(m_program, "proj");

    // VAO / VBO
    glGenVertexArrays(1, &m_vao);
    glGenBuffers(1, &m_vbo);

    // Noise-Textur
    m_noiseTex = createNoiseTexture();

    m_ready = true;
    return true;
}

// ── Shader-Kompilierung ───────────────────────────────────────────────────────

GLuint CGlassRenderer::compileShader(GLenum type, const std::string& src) {
    GLuint shader = glCreateShader(type);
    const char* srcPtr = src.c_str();
    glShaderSource(shader, 1, &srcPtr, nullptr);
    glCompileShader(shader);

    GLint ok = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char log[2048];
        glGetShaderInfoLog(shader, sizeof(log), nullptr, log);
        // Hyprland-eigenes Logging
        Debug::log(ERR, "[LiquidGlass] Shader compile error: {}", log);
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

bool CGlassRenderer::compileShaders() {
    GLuint vert = compileShader(GL_VERTEX_SHADER,   Shaders::VERT_SRC);
    GLuint frag = compileShader(GL_FRAGMENT_SHADER, Shaders::FRAG_SRC);

    if (!vert || !frag) {
        if (vert) glDeleteShader(vert);
        if (frag) glDeleteShader(frag);
        return false;
    }

    m_program = glCreateProgram();
    glAttachShader(m_program, vert);
    glAttachShader(m_program, frag);

    glDeleteShader(vert);
    glDeleteShader(frag);

    return true;
}

bool CGlassRenderer::linkProgram() {
    glLinkProgram(m_program);
    GLint ok = 0;
    glGetProgramiv(m_program, GL_LINK_STATUS, &ok);
    if (!ok) {
        char log[2048];
        glGetProgramInfoLog(m_program, sizeof(log), nullptr, log);
        Debug::log(ERR, "[LiquidGlass] Program link error: {}", log);
        return false;
    }
    return true;
}

// ── Noise-Textur ─────────────────────────────────────────────────────────────

GLuint CGlassRenderer::createNoiseTexture() {
    constexpr int SIZE = 256;
    std::vector<uint8_t> data(SIZE * SIZE * 4);

    std::mt19937 rng(42);
    std::uniform_int_distribution<int> dist(0, 255);

    for (auto& b : data)
        b = static_cast<uint8_t>(dist(rng));

    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, SIZE, SIZE,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, data.data());
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,     GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,     GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0);

    return tex;
}

// ── Quad hochladen ────────────────────────────────────────────────────────────

void CGlassRenderer::uploadQuad(const CBox& geo) {
    const float x = geo.x, y = geo.y;
    const float w = geo.w, h = geo.h;

    // pos(xy) + texcoord(uv)
    float verts[] = {
        x,     y,     0.0f, 0.0f,
        x + w, y,     1.0f, 0.0f,
        x,     y + h, 0.0f, 1.0f,
        x + w, y + h, 1.0f, 1.0f,
    };

    glBindVertexArray(m_vao);
    glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(verts), verts, GL_DYNAMIC_DRAW);

    // Attribut 0: Position (xy)
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float), (void*)0);

    // Attribut 1: Texturkoordinaten (uv)
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE,
                          4 * sizeof(float), (void*)(2 * sizeof(float)));
}

// ── Uniforms binden ───────────────────────────────────────────────────────────

void CGlassRenderer::bindUniforms(
    const CBox& geo, float alpha, const SGlassConfig& cfg)
{
    const auto& u = m_uniforms;

    // Monitor-Auflösung aus dem Compositor holen
    const auto* monitor = g_pCompositor->m_pLastMonitor.get();
    float resX = monitor ? monitor->vecPixelSize.x : 1920.0f;
    float resY = monitor ? monitor->vecPixelSize.y : 1080.0f;

    glUniform1i(u.tex,           0);
    glUniform1i(u.texNoise,      1);
    glUniform2f(u.resolution,    resX, resY);
    glUniform1f(u.time,          m_time);
    glUniform1f(u.radius,        cfg.cornerRadius);
    glUniform1f(u.blurStrength,  cfg.blurStrength);
    glUniform1f(u.refractionStr, cfg.refractionStr);
    glUniform1f(u.opacity,       cfg.opacity * alpha);
    glUniform4f(u.tintColor,
                cfg.tintColor[0], cfg.tintColor[1],
                cfg.tintColor[2], cfg.tintColor[3]);
    glUniform2f(u.windowPos,  geo.x, geo.y);
    glUniform2f(u.windowSize, geo.w, geo.h);
}

// ── Haupt-Render-Funktion ─────────────────────────────────────────────────────

void CGlassRenderer::renderWindow(
    PHLWINDOW       window,
    const CBox&     geometry,
    float           alpha,
    const SGlassConfig& cfg)
{
    if (!m_ready) return;

    // Zeit hochzählen
    static auto startTime = std::chrono::steady_clock::now();
    auto now   = std::chrono::steady_clock::now();
    m_time     = std::chrono::duration<float>(now - startTime).count();

    // Hintergrund-Textur (blur pass) aus Hyprlands OpenGL-Renderer holen
    GLuint bgTex = g_pHyprOpenGL->m_RenderData.pCurrentMonData->blurFB.m_cTex.m_iTexID;

    glUseProgram(m_program);

    // Projektionsmatrix: Identität reicht für Screen-Space
    float proj[16] = {
         2.0f / geometry.w,  0.0f,              0.0f, 0.0f,
         0.0f,              -2.0f / geometry.h, 0.0f, 0.0f,
         0.0f,               0.0f,              1.0f, 0.0f,
        -1.0f,               1.0f,              0.0f, 1.0f
    };
    glUniformMatrix4fv(m_uniforms.proj, 1, GL_FALSE, proj);

    // Texturen binden
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, bgTex);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, m_noiseTex);

    bindUniforms(geometry, alpha, cfg);
    uploadQuad(geometry);

    // Alpha-Blending
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glDisable(GL_BLEND);
    glBindVertexArray(0);
    glUseProgram(0);
}