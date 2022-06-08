// https://iquilezles.org/articles/distfunctions/ !!!

float intersectSDF(float distA, float distB) {
    return max(distA, distB);
}

float unionSDF(float distA, float distB) {
    return min(distA, distB);
}

float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}

float sphereSDF(vec3 p, vec3 c, float r){
    return length(p - c) - r;
}

float torusSDF( vec3 p, vec2 t ){
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

float boxroundSDF( vec3 p, vec3 b, float r ){
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float planeSDF( vec3 p, vec3 n, float h )
{
  // n must be normalized
  return dot(p,n) + h;
}

vec3 opRep( in vec3 p, in vec3 c ){
    return mod(p+0.5*c,c)-0.5*c;
}

float opDisplace( in float d1, in vec3 p ){
    float dt = 2;
    float dd = 0.2;

    float d2 = sin(dt*p.x)*sin(dt*p.y)*sin(dt*p.z)*dd;
    return d1+d2;
}