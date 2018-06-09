#version 410

#include "hg_sdf.glsl"
#include "uniforms.glsl"
#include "noise.glsl"

out vec4 fragColor;


float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}

float rand(vec3 co){
    return fract(sin(dot(co.xyz ,vec3(12.9898,78.233,43.2536))) * 43758.5453);
}

float func(vec2 p)
{
   vec2 pp = floor(p);
   
   return uFFT[];
    
   //return 0.4*(2.5+sin(pp.x-uTime)+sin(pp.y-uTime));
}

float bars( vec3 p, vec2 c )
{
    vec2 q = mod(p.xz,c)-0.5*c;
    return fBox( vec3(q.x, p.y, q.y),
        vec3( 0.45, func(p.xz), 0.45 ));
}

void main()
{
    vec2 uv = gl_FragCoord.xy / uRes.xy;
    vec2 uvn = vec2(uv.x*3.55555555-1.77777777, uv.y*2-1);
    
    vec3 ro = uPos*10;//vec3(0.0, 0.0, 10.0);
    vec3 rd = normalize(vec3(uvn.x*0.5, uvn.y*0.5-0.5f, -1.0));
    
    float depth = 0.0;
    for (int i=0; i<48; ++i) {
        vec3 p = ro + depth*rd;
        float d = bars(p, vec2(1.0));
        
        if (d < 0.01)
            break;
        
        if (i % 3 == 0) 
            depth += (0.6+rand(p)*0.4)*d;
        else
            depth += d;

        if (depth > 100.0) {
            depth = 100.0;
            break;
        }
    }
    
    depth = (depth*0.05)-0.2; 
    
    //float clip = step(0, sin(length(uv - uPos.xy) * 10));
    fragColor = vec4(depth, depth, depth, 1);
}
