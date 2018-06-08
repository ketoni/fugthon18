#version 410

#include "hg_sdf.glsl"
#include "uniforms.glsl"

out vec4 fragColor;


float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}


void main()
{
    vec2 uv = gl_FragCoord.xy / uRes.xy;
    
    vec3 ro = uPos*10;//vec3(0.0, 0.0, 10.0);
    vec3 rd = vec3(uv, -1.0);
    
    float depth = 0.0;
    for (int i=0; i<64; ++i) {
        float d = sdTorus(ro + depth*rd, vec2(2.0, 0.5));
        
        if (d < 0.00001)
            break;
        
        depth += d;
    }
    
    depth *= 0.01; 
    
    //float clip = step(0, sin(length(uv - uPos.xy) * 10));
    fragColor = vec4(depth, depth, depth, 1);
}
