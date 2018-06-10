#version 410

#include "uniforms.glsl"

uniform float uPlasma;
uniform float uVertical;
uniform float uDistance;
uniform float uZoom;
out vec4 fragColor;


float udBox(vec3 p, vec3 b )
{
    return length(max(abs(p)-b,0.0));
}

void pDis(vec3 p, float a) {
    p = vec3(1.0);
}

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

void main()
{
    vec3 pos = vec3(0.0, uVertical, uDistance);
    vec3 box = vec3(1.0, 1.0, 10.0);

    vec3 ro = pos * 3.0;
    vec2 uv = gl_FragCoord.xy / uRes.xy * 2 - 1;
    vec3 rd = normalize(vec3(uv, uZoom));
     pR(rd.xy, 0.5*uTime);

    vec3 p, q;
    mat2 m;
    float c, s, d, far = 4;

    float depth = 0.0;
    for (int i=0; i<32; ++i) {

        p = ro + depth*rd;
        pR(p.yz, 2*uTime);

        c = cos(p.x);
        s = sin(p.x);
        m = mat2(c,-s,s,c);
        q = vec3(m*p.yz,p.x);

        d = udBox(q, box);
        // d = udBox(p, size);

        if (d < 0.000001)
            break;

        depth += uPlasma * d;
        if (depth > far) {
            fragColor = vec4(100, 0.8 - length(uv) * 0.4, 0, 1.0);
            return;
        }
    }

    
    depth = 1.0 - depth / far - ((0.5 + 2 * uFFT[0]) * 1);
    fragColor = vec4(depth, 0.0, 0.5, 1.0);
}
