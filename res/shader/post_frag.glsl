#version 410

#include "uniforms.glsl"

uniform float uScene;

uniform sampler2D uColorSampler;

out vec4 fragColor;

void main()
{
    const float gamma = 2.2;
    vec2 uv = gl_FragCoord.xy / uRes;
    vec2 cDiff = uv * 2 - 1;
    vec3 color = texture(uColorSampler, uv).rgb;
    color = pow(color, vec3(1 / gamma));
    float scanlines = 1 + 0.15 * sin(uv.y * 900);
    float pixelrows = 1 + 0.05 * sin(uv.x * 1600);
    float screenborder = 1 - length(pow(cDiff, vec2(3)));
    fragColor = vec4(color * scanlines * pixelrows * screenborder, 1);
}
