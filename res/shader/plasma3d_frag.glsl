#version 410

#include "uniforms.glsl"
#include "noise.glsl"

// Constants
#define MAX_STEPS 256
#define MIN_DEPTH 0
#define MAX_DEPTH 10
#define EPSILON 0.0001
#define PI 3.145

// Inputs
uniform float uIntensity;
uniform float uMotion;
uniform float uYPos;

// Outputs
out vec4 fragColor;

struct Material {
    vec3 albedo;
    float roughness;
    float metalness;
    vec3 emissivity;
};

vec3 cartToPol(vec3 p) {
    float ro = length(p);
    float delta = acos(p.z / ro);
    float phi = atan(p.y / p.x);
    return vec3(ro, delta, phi);
}

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float fSphere(vec3 p, float r) {
    return length(p) - r;
}

float fBlob(vec3 p, float s) {
    pR(p.xz, uTime);
    pR(p.yz, 0.5 * sin(uTime));
    pR(p.yx, 2 * uTime);
    float highs = 5 * uFFT[5] * cos((p.x + sin(uTime)) * 20) * cos((p.y * 20) + cos(uTime)) * cos(p.z * 20);
    float mids = 12 * uFFT[2]  * cos((p.x + sin(uTime)) * 10) * cos((p.y * 10) + cos(uTime)) * cos(p.z * 10);
    float lows = 2 * uFFT[0] * cos((p.x + PI * sin(uTime)) * 2) * cos((p.y + 0.5 * cos(uTime)) * 2) * cos((p.z + 3 * sin(uTime))* 2);
    return fSphere(p, s + lows + mids + highs);
}

float fScene(vec3 p)
{
    p -= vec3(0, uYPos, 0);
    return fBlob(p - vec3(0, -0.1, 0), 0.8);
}

vec3 genViewRay(float fov)
{
    vec2 xy = gl_FragCoord.xy - uRes.xy * 0.5;
    float z = uRes.y / tan(radians(fov * 0.5));
    return normalize(vec3(xy, z));
}

void main()
{
    vec2 cPos = gl_FragCoord.xy / uRes.xy * 2 - 1;
    // Camera stuff
    vec3 o = vec3(0, 0, -5);
    vec3 d = genViewRay(60);
    // TODO: orientation here

    // Fire away
    float t = MIN_DEPTH;
    for (int i = 0; i < MAX_STEPS; ++i) {
        // Calculate distance to field
        float depth = fScene(o + t * d);

        // Stop if we overshot
        if (depth < t * EPSILON) break;

        // March up to distance
        t += depth;

        // Stop if we went past max distance
        if (t > MAX_DEPTH) break;
    }

    // Early out if nothing was hit
    if (t > MAX_DEPTH) {
        fragColor = 1.6 * vec4(0.5, 0.2, 0, 1);
        return;
    }

    // Calculate hit position from final distance
    vec3 hit_pos = o + t * d;
    float depth = pow(1 - t / 2.7, 2);
    fragColor = 1.6 * vec4(depth, 0, depth * depth, 1);
}
