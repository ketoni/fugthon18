#version 410

#include "uniforms.glsl"

uniform sampler2D uHDRSampler;

const float exposure = 1.0;

out vec4 fragColor;

void main()
{
    const float gamma = 2.2;
    vec2 texCoord = gl_FragCoord.xy / uRes;
    vec3 hdr = texture(uHDRSampler, texCoord).rgb;
    vec3 mapped = vec3(1) - exp(-hdr * exposure);
    mapped = pow(mapped, vec3(1 / gamma));
    fragColor = vec4(mapped, 1);
}