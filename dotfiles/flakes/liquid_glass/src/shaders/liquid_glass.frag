#version 320 es
precision highp float;

in vec2 vTexCoord;
in vec2 vPos;

out vec4 fragColor;

uniform sampler2D tex;          // Hintergrund (Blur-Textur)
uniform sampler2D texNoise;     // Noise für Liquid-Verzerrung
uniform vec2      resolution;
uniform float     time;
uniform float     radius;       // Abrundungsradius
uniform float     blurStrength; // Stärke der Unschärfe
uniform float     refractionStrength;
uniform float     opacity;
uniform vec4      tintColor;    // RGBA Tint
uniform vec2      windowPos;    // Position des Fensters
uniform vec2      windowSize;   // Größe des Fensters

// ── Hilfsfunktionen ──────────────────────────────────────────────────────────

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Einfaches Box-Blur via mehrfaches Sampling
vec4 sampleBlur(sampler2D s, vec2 uv, float strength) {
    vec4 color = vec4(0.0);
    float total = 0.0;
    vec2 texelSize = 1.0 / resolution;

    int samples = 12;
    for (int i = -samples; i <= samples; i++) {
        for (int j = -samples; j <= samples; j++) {
            float weight = exp(-float(i * i + j * j) / (2.0 * strength * strength));
            vec2 offset = vec2(float(i), float(j)) * texelSize * strength;
            color += texture(s, uv + offset) * weight;
            total += weight;
        }
    }
    return color / total;
}

// Chromatische Abberation (Prismeneffekt wie echtes Glas)
vec4 sampleChromatic(sampler2D s, vec2 uv, vec2 distortion) {
    float r = texture(s, uv + distortion * 1.0).r;
    float g = texture(s, uv + distortion * 0.666).g;
    float b = texture(s, uv + distortion * 0.333).b;
    float a = texture(s, uv).a;
    return vec4(r, g, b, a);
}

// Fresnel-Term: Randbereich erscheint stärker reflektiert
float fresnel(vec2 uv, vec2 center, float power) {
    vec2  d = uv - center;
    float dist = length(d) * 2.0;
    return pow(clamp(dist, 0.0, 1.0), power);
}

// Liquid-Verzerrung via Noise-Textur + Zeit
vec2 liquidDistortion(vec2 uv) {
    vec2 noiseUV = uv * 3.0 + vec2(time * 0.05, time * 0.03);
    vec4 n = texture(texNoise, noiseUV);
    float dx = (n.r - 0.5) * 2.0;
    float dy = (n.g - 0.5) * 2.0;
    return vec2(dx, dy) * refractionStrength * 0.01;
}

// ── Main ─────────────────────────────────────────────────────────────────────

void main() {
    vec2 uv     = vTexCoord;
    vec2 aspect = vec2(windowSize.x / windowSize.y, 1.0);

    // Koordinaten relativ zur Fenstermitte (–0.5 … +0.5)
    vec2 localUV  = (uv - 0.5);
    vec2 halfSize = vec2(0.5);
    float r       = radius / windowSize.y;

    // SDF für gerundetes Rechteck → Maske
    float sdf  = sdRoundBox(localUV * aspect, halfSize * aspect, r * aspect.x);
    float mask = 1.0 - smoothstep(-0.002, 0.002, sdf);

    if (mask < 0.001) discard;

    // Liquid-Verzerrung berechnen
    vec2 distort = liquidDistortion(uv);

    // Blurred & verzerrter Hintergrund
    vec4 blurred = sampleBlur(tex, uv + distort, blurStrength);

    // Chromatische Abberation am Rand
    float fr = fresnel(uv, vec2(0.5), 2.5);
    vec4  chromatic = sampleChromatic(tex, uv + distort, distort * fr * 0.5);

    // Glasfarbe: Misch blurred + chromatisch
    vec4 glassColor = mix(blurred, chromatic, fr * 0.4);

    // Spiegelglanz-Highlight oben-links (Richtungslicht)
    vec2  highlightUV = localUV + vec2(0.2, 0.25);
    float highlight   = exp(-dot(highlightUV, highlightUV) * 8.0) * 0.35;

    // Rand-Glow
    float edgeGlow = smoothstep(0.01, 0.0, abs(sdf)) * 0.25;

    // Tint überlagern
    vec4 tinted = mix(glassColor, tintColor, tintColor.a * 0.15);

    // Alles zusammenmischen
    vec4 result = tinted;
    result.rgb += highlight;
    result.rgb += edgeGlow * vec3(1.0, 1.0, 1.0);
    result.a    = opacity * mask;

    fragColor = result;
}