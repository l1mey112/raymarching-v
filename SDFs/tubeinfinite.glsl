float de(vec3 p){
    #define R(a)a=vec2(a.x+a.y,a.x-a.y)*.7
    #define G(a,n)R(a);a=abs(a)-n;R(a)
      p=fract(p)-.5;
      G(p.xz,.3);
      G(p.zy,.1);
      G(p.yz,.15);
      return .6*length(p.xy)-.01;
    #undef R
    #undef G
}