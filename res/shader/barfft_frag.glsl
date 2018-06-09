#version 410

#include "hg_sdf.glsl"
#include "uniforms.glsl"
#include "noise.glsl"

out vec4 fragColor;

const float amp[8] = float[](2, 16, 20, 25, 30, 60, 100, 180);
const float tm[8] = float[](10/1, 10/2, 10/3, 10/4, 10/5, 10/6, 10/7, 10/8);

float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}

float rand(vec3 co){
    return fract(sin(dot(co.xyz ,vec3(12.9898,78.233,43.2536))) * 43758.5453);
}

float plasma1(vec2 p, vec2 th, float s)
{
     return 0.5+0.5*sin(s*(p.x*sin(uTime/th.x)+p.y*cos(uTime/th.y))+uTime); 
}

float plasma2(vec2 p, vec2 cs, vec2 th, float s) {
    vec2 c = p + cs * vec2(sin(uTime/th.x), cos(uTime/th.y));
    return 0.5+0.5*sin(sqrt(s*(c.x*c.x+c.y*c.y)+1)+uTime);
}

float func(vec2 p)
{
    vec2 pp = floor(p);
    return
        1.7*(
        amp[0]*uFFT[0]*plasma2(pp, vec2(30, 40), vec2(5, 3), 0.1) +
        amp[1]*uFFT[1]*plasma1(pp, vec2(2, 3), 0.25) +
        amp[2]*uFFT[2]*plasma1(pp, vec2(-7, 9), 0.5) +
        amp[3]*uFFT[3]*(0.5+0.5*sin((pp.y*0.5-uTime*1.5))) +
        amp[4]*uFFT[4]*plasma1(pp, vec2(-3, -7), 1.0) +
        amp[5]*uFFT[5]*plasma2(pp, vec2(25, -18), vec2(5, 3), 0.1) +
        amp[6]*uFFT[6]*(0.5+0.5*sin((pp.x*4-uTime*5.5))) +
        amp[7]*uFFT[7]*plasma2(pp, vec2(15, 12), vec2(1.2, 1), 3.2)
        ); 
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
    
    float t = uTime*0.4;
    
    vec3 ro = vec3(30.0f*cos(t), 8.0+sin(t*0.2), 25.0f*sin(t));
    vec3 rt = vec3(30.0f*cos(t+0.4), 2.0, 25.0f*sin(t+0.4f));

    //vec3 rt = vec3(3.0f*cos(t*0.756), 1.0, -4.0f*sin(t*0.456));
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
    
    float a = p.y*0.25;
    if (a<0) a=0;
    
    float r = 2*(2/(4*a+1)-0.1-1/(a*8));
    //float r = 2-2*a-(1/(10*a));
     
    fragColor = vec4(r, 0.0, 0.0, 1.0);


}
