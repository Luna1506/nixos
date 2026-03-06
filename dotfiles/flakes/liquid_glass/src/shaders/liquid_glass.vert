#version 320 es
precision highp float;

layout(location = 0) in vec2 pos;
layout(location = 1) in vec2 texcoord;

out vec2 vTexCoord;
out vec2 vPos;

uniform mat4 proj;

void main() {
    vTexCoord = texcoord;
    vPos      = pos;
    gl_Position = proj * vec4(pos, 0.0, 1.0);
}