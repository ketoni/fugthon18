#version 410

#include "hg_sdf.glsl"
#include "uniforms.glsl"

out vec4 fragColor;

void main()
{
    vec2 uv = gl_FragCoord.xy / uRes.xy;

    float clip = step(0, sin(length(uv - uPos.xy) * 10));
    fragColor = vec4(uColor * clip , 1);
}
