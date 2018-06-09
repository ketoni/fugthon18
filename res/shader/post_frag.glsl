#version 410

#include "uniforms.glsl"

uniform float uScene;

uniform sampler2D uHDRSampler;

const float exposure = 2.5;

out vec4 fragColor;

void main()
{
    const float gamma = 2.2;
    vec2 uv = gl_FragCoord.xy / uRes;
    vec2 cDiff = uv * 2 - 1;
    vec3 hdr = texture(uHDRSampler, uv).rgb;
    vec3 mapped = vec3(1) - exp(-hdr * exposure);
    mapped = pow(mapped, vec3(1 / gamma));
    float scanlines = 1 + 0.2 * sin(uv.y * 900);
    float pixelrows = 1 + 0.1 * sin(uv.x * 1600);
    float screenborder = 1 - length(pow(cDiff, vec2(5)));
    fragColor = vec4(mapped * scanlines * pixelrows * screenborder, 1);
}
