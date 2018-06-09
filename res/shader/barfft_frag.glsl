#version 410

//#include "hg_sdf.glsl"
#include "uniforms.glsl"

out vec4 fragColor;


float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}


float func(vec2 p)
{
    return 0.1*(2.5+sin(p.x-uTime)+sin(p.y*p.y*0.6-uTime*0.867));
}

float bars( vec3 p, vec3 c )
{
    vec2 q = mod(p.xz,c.xz)-0.5*c.xz;
    return udBox( vec3(q.x, p.y, q.y),
        vec3( func(floor(p.xz*0.5))) );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / uRes.xy;
    vec2 uvn = vec2(uv.x*3.55555555-1.77777777, uv.y*2-1);
    
    vec3 ro = uPos*10;//vec3(0.0, 0.0, 10.0);
    vec3 rd = normalize(vec3(uvn*0.5, -1.0));
    
    float depth = 0.0;
    for (int i=0; i<64; ++i) {
        //float d = sdTorus(ro + depth*rd, vec2(2.0, 0.5));
        float d = bars(ro + depth*rd, vec3(2.0, 2.0, 2.0));
        
        if (d < 0.00001)
            break;
        
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
