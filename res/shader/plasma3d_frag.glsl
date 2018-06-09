#version 410

#include "uniforms.glsl"
#include "noise.glsl"

// Constants
#define MAX_STEPS 256
#define MIN_DEPTH 0
#define MAX_DEPTH 10
#define EPSILON 0.0001
#define EPSILON 0.0001

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

float fScene(vec3 p)
{
    pR(p.xz, uTime);
    float highs = 5 * uFFT[7] * cos(p.x * 20) * cos(p.y * 20) * cos(p.z * 20);
    float mids = 4 * uFFT[4]  * cos(p.x * 10) * cos(p.y * 10) * cos(p.z * 10);
    float lows = 3 * uFFT[1] * cos((p.x + sin(uTime)) * 2) * cos((p.y + 4 * sin(uTime)) * 2) * cos((p.z + 3 * sin(uTime))* 2);
    return fSphere(p, 0.7+ lows + mids + highs);
}

vec3 genViewRay(float fov)
{
    vec2 xy = gl_FragCoord.xy - uRes.xy * 0.5;
    float z = uRes.y / tan(radians(fov * 0.5));
    return normalize(vec3(xy, z));
}

void main()
{
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
        fragColor = vec4(0);
        return;
    }

    // Calculate hit position from final distance
    vec3 hit_pos = o + t * d;
    fragColor = vec4(vec3(pow(1 - t / 3, 4)), 1);
}
