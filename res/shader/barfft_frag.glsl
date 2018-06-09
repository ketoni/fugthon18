#version 410

#include "hg_sdf.glsl"
#include "uniforms.glsl"
#include "noise.glsl"

out vec4 fragColor;

const float amp[8] = float[](2, 4, 8, 12, 16, 24, 32, 40);
const float tm[8] = float[](5, 5, 5, 5, 5, 5, 5, 5);

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
   
   //return uFFT[];
   return 1;
  /* 
   return
       amp[0]*uFFT[0]*(1.1+sin((pp.x-uTime*tm[0])/2)) +
       amp[1]*uFFT[1]*(1.1+sin((pp.y-uTime*tm[1])/2)) +
       amp[2]*uFFT[2]*(1.1+sin((pp.x-uTime*tm[2])/1)) +
       amp[3]*uFFT[3]*(1.1+sin((pp.y-uTime*tm[3])/1)) +
       amp[4]*uFFT[4]*(1.1+sin((pp.x-uTime*tm[4])*2)) +
       amp[5]*uFFT[5]*(1.1+sin((pp.y-uTime*tm[5])*2)) +
       amp[6]*uFFT[6]*(1.1+sin((pp.x-uTime*tm[6])*4)) +
       amp[7]*uFFT[7]*(1.1+sin((pp.y-uTime*tm[7])*4));
*/
}

float bars( vec3 p, vec2 c )
{
    vec2 q = mod(p.xz,c)-0.5*c;
    return fBox( vec3(q.x, p.y, q.y),
        vec3( 0.25, func(p.xz), 0.25 ));
}

void main()
{
    vec2 uv = gl_FragCoord.xy / uRes.xy;
    vec2 uvn = vec2(uv.x*3.55555555-1.77777777, uv.y*2-1);    
    
    float t = uTime*0.5;
    
    vec3 ro = vec3(10.0f*cos(t), 5.0, 10.0f*sin(t));
    vec3 rt = vec3(5.0f*cos(t*0.456), 2.0, 5.0f*sin(t*0.456));
    mat3 co;
    co[2] = normalize(ro-rt);
    co[0] = cross(co[2], vec3(0.0, -1.0, 0.0));
    co[1] = cross(co[2], co[0]); 
    
    vec3 rd = co * normalize(vec3(uvn.x*0.5, uvn.y*0.5, -1.0));
    
    float depth = 0.0;
    vec3 p;
    for (int i=0; i<32; ++i) {
        p = ro + depth*rd;
        float d = bars(p, vec2(1.0));
        
        if (d < 0.01)
            break;
        
        //if (i % 3 == 0) 
        //    depth += (0.6+rand(p)*0.4)*d;
        //else
            depth += d;

        if (depth > 100.0) {
            depth = 100.0;
            break;
        }
    }
    
    depth = (depth*0.05)-0.2; 
    
    //float clip = step(0, sin(length(uv - uPos.xy) * 10));
    fragColor = vec4(p.y, p.y*p.y, p.y*p.y*p.y, 1);
}
