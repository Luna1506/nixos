#pragma once

// ─── hyprfrost GLSL shaders ───────────────────────────────────────────────────
//
// Rendering pipeline overview
// ───────────────────────────
//   1. Hyprland composites everything *behind* the window and (when blur is
//      enabled) applies its own Kawase-blur pass to that region.
//   2. Our decoration sits in DECORATION_LAYER_UNDER, so it draws on top of
//      that already-blurred background but underneath the window surface.
//   3. We draw two quads:
//        a) A tinted, semi-transparent rectangle  → the "glass colour"
//        b) A procedural noise quad               → the "frost / grain"
//      Together with Hyprland's blur they produce a convincing frosted-glass
//      effect identical in spirit to macOS vibrancy.
//
// All shaders target GLSL ES 3.20 (OpenGL ES 3.2) which is what Hyprland uses.

#include <string>

// ── 1. Noise vertex shader ────────────────────────────────────────────────────
// We pass TWO sets of coordinates per vertex:
//   a_clipPos   – normalised device coords  (-1…+1)
//   a_screenPos – actual pixel coordinates  (used as noise seed)
inline const std::string HYPRFROST_VERT = R"(
#version 320 es
precision highp float;

in vec2 a_clipPos;
in vec2 a_screenPos;

out vec2 v_screenPos;

void main() {
    gl_Position = vec4(a_clipPos, 0.0, 1.0);
    v_screenPos = a_screenPos;
}
)";

// ── 2. Noise / frost fragment shader ─────────────────────────────────────────
// This shader renders a subtle procedural grain on top of the tinted glass.
// It does NOT read the framebuffer – it purely generates a noise pattern and
// blends it with gl_FragColor via OpenGL blending (GL_ONE / GL_ONE_MINUS_SRC_ALPHA
// or additive, configured at draw time).
inline const std::string HYPRFROST_FRAG = R"(
#version 320 es
precision highp float;

// ── uniforms ─────────────────────────────────────────────────────────────────
uniform float u_noiseAmount;   // 0.0 = no grain, 0.05 = subtle, 0.15 = heavy
uniform float u_noiseScale;    // pixel scale of the noise pattern (default 300)
uniform float u_opacity;       // overall opacity of the noise layer

in vec2 v_screenPos;
out vec4 fragColor;

// ── helpers ──────────────────────────────────────────────────────────────────

// Classic hash – fast, good distribution
float hash(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

// Value noise – bilinear interpolation over a hash grid
float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    // Smooth Hermite
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x),
               mix(c, d, f.x),
               f.y);
}

// Two octaves of noise for a richer frost texture
float fbm(vec2 p) {
    float v  = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 2; ++i) {
        v   += amp * valueNoise(p);
        p   *= 2.1;
        amp *= 0.5;
    }
    return v;
}

// ── main ─────────────────────────────────────────────────────────────────────
void main() {
    // Noise seed comes from the physical pixel position → no UV stretching
    vec2 uv = v_screenPos / u_noiseScale;

    float n = fbm(uv);

    // Centre the noise around 0 so it doesn't uniformly brighten/darken
    float grain = (n - 0.5) * u_noiseAmount;

    // Output: white noise with very low alpha – blends subtly over tint
    fragColor = vec4(vec3(0.5 + grain), u_opacity * abs(grain) * 2.0);
}
)";
