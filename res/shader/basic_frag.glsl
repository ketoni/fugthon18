#version 410

//#include "hg_sdf.glsl"
#include "uniforms.glsl"

out vec4 fragColor;

void main()
{
    vec2 uv = gl_FragCoord.xy / uRes.xy;

    float sum = 0;
    int l = 5;
    for (int i = 0; i < l; ++i) {
        sum += uFFT[int(uv.x * 1024 / l) + i];
    }
    float clip = step(0, sin(length(uv - uPos.xy) * 10));
    if (sum > uv.y)
        fragColor = vec4(uColor.r, uColor.g * sum, uColor.b * uv.y, 1);
    else
        fragColor = vec4(0, 0, 0, 1);
}
