#version 410

#include "uniforms.glsl"

out vec4 fragColor;

void main()
{
    vec2 uv = gl_FragCoord.xy / uRes.xy;

    float sum = 0;
    float clip = step(0, sin(length(uv - uPos.xy) * 10));
    fragColor = vec4(vec3(sum), 1);
}
