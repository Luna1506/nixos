#pragma once

#include <GLES3/gl32.h>
#include <string>
#include <array>
#include <optional>

// Hyprland Plugin API (>= 0.45)
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/desktop/Window.hpp>

struct SGlassUniforms {
    GLuint tex              = 0;
    GLuint texNoise         = 0;
    GLuint resolution       = 0;
    GLuint time             = 0;
    GLuint radius           = 0;
    GLuint blurStrength     = 0;
    GLuint refractionStr    = 0;
    GLuint opacity          = 0;
    GLuint tintColor        = 0;
    GLuint windowPos        = 0;
    GLuint windowSize       = 0;
    GLuint proj             = 0;
};

struct SGlassConfig {
    float blurStrength      = 18.0f;
    float refractionStr     = 0.6f;
    float opacity           = 0.72f;
    float cornerRadius      = 14.0f;
    std::array<float, 4> tintColor = {0.95f, 0.95f, 1.0f, 0.08f};
    bool  animate           = true;
};

class CGlassRenderer {
public:
    CGlassRenderer();
    ~CGlassRenderer();

    // Initialisiert Shader & GL-Ressourcen
    bool init();

    // Rendert den Liquid-Glass-Effekt für ein Fenster
    void renderWindow(
        PHLWINDOW       window,
        const CBox&     geometry,
        float           alpha,
        const SGlassConfig& cfg
    );

    void setConfig(const SGlassConfig& cfg) { m_config = cfg; }
    bool isReady() const { return m_ready; }

private:
    bool        compileShaders();
    GLuint      compileShader(GLenum type, const std::string& src);
    bool        linkProgram();
    void        bindUniforms(const CBox& geo, float alpha, const SGlassConfig& cfg);
    GLuint      createNoiseTexture();
    void        uploadQuad(const CBox& geo);

    GLuint      m_program  = 0;
    GLuint      m_vao      = 0;
    GLuint      m_vbo      = 0;
    GLuint      m_noiseTex = 0;
    SGlassUniforms m_uniforms;
    SGlassConfig   m_config;

    float       m_time     = 0.0f;
    bool        m_ready    = false;
};