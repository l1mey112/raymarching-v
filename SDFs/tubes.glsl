float de(vec3 p) {
    const float width=.22;
    const float scale=4.;
    float t=0.2;
    float dotp=dot(p,p);
    p.x+=sin(t*40.)*.007;
    p=p/dotp*scale;
    p=sin(p+vec3(sin(1.+t)*2.,-t,-t*2.));
    float d=length(p.yz)-width;
    d=min(d,length(p.xz)-width);
    d=min(d,length(p.xy)-width);
    d=min(d,length(p*p*p)-width*.3);
    return d*dotp/scale;
}