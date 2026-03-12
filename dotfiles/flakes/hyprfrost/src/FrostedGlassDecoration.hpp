#pragma once

// ─── FrostedGlassDecoration ───────────────────────────────────────────────────
//
// A Hyprland IHyprWindowDecoration that renders a frosted-glass effect behind
// every mapped window.
//
// Rendering stack (bottom → top):
//   [Wallpaper / windows below]
//     ↓  Hyprland's Kawase-blur pass (decoration:blur:enabled = true)
//   [Blurred background]
//     ↓  Our decoration  (DECORATION_LAYER_UNDER)
//       1. Tinted semi-transparent rect  ← "glass colour"
//       2. Procedural noise quad         ← "frost grain"
//   [Window surface & over-decorations]
//
// Hyprland version compatibility: 0.44 – 0.46 (nixos-unstable, 2025-03).

#include <GLES3/gl32.h>
#include <hyprland/src/render/decorations/IHyprWindowDecoration.hpp>
#include <hyprland/src/helpers/math/Math.hpp>

class CFrostedGlassDecoration : public IHyprWindowDecoration {
  public:
    explicit CFrostedGlassDecoration(PHLWINDOW pWindow);
    ~CFrostedGlassDecoration() override;

    // ── IHyprWindowDecoration interface ──────────────────────────────────────
    SDecorationPositioningInfo      getPositioningInfo()                          override;
    void                            onPositioningReply(const SDecorationPositioningReply&) override;
    void                            draw(PHLMONITOR, float const& renderRatio)    override;
    eDecorationType                 getDecorationType()                           override;
    void                            updateWindow(PHLWINDOW)                       override;
    void                            damageEntire()                                override;
    eDecorationLayer                getDecorationLayer()                          override;
    uint64_t                        getDecorationFlags()                          override;
    std::string                     getDisplayName()                              override;

  private:
    // ── window reference ─────────────────────────────────────────────────────
    PHLWINDOWREF  m_pWindow;
    CBox          m_assignedBox{};   // filled in onPositioningReply

    // ── GL resources (lazily initialised on first draw) ───────────────────────
    bool    m_glReady        = false;
    GLuint  m_prog           = 0;   // noise shader program
    GLuint  m_vao            = 0;
    GLuint  m_vbo            = 0;

    // uniform locations
    GLint   m_uNoiseAmount   = -1;
    GLint   m_uNoiseScale    = -1;
    GLint   m_uOpacity       = -1;

    // ── helpers ───────────────────────────────────────────────────────────────
    bool    initGL();
    void    destroyGL();
    GLuint  compileShader(GLenum type, const std::string& src);
    bool    linkProgram(GLuint vert, GLuint frag);

    /// Render the noise/grain overlay using the custom shader.
    void    renderNoise(const CBox& box, PHLMONITOR pMonitor,
                        float noiseAmount, float noiseScale, float opacity);
};
