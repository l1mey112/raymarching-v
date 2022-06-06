@vs vs
in vec4 position;
in vec2 texcoord0;

out vec2 uv;

void main() {
    gl_Position = position;
    uv = texcoord0;
}
@end

@fs fs
uniform fs_params {
	vec2 iResolution;
    float iAspect;
    float iTime;
    vec3 cPosition;
    float cFocal;
    float fInter;
    mat4 cMatrix;
};

in vec2 uv;
out vec4 frag_color;

vec3 circ2d(vec2 vv, float size){
    return length(vv) < size ? vec3(1) : vec3(0);
}

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

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

/* float de(vec3 p) {
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
  } */

/* float de(vec3 p){
    p.xz=fract(p.xz)-.5;
    float k=1.;
    float s=0.;
    for(int i=0;i++<9;)
      s=2./clamp(dot(p,p),.1,1.),
      p=abs(p)*s-vec3(.5,3,.5),
      k*=s;
    return length(p)/k-.001;
  } */

float de( vec3 p ){
    p=abs(p)-1.2;
    if(p.x < p.z)p.xz=p.zx;
    if(p.y < p.z)p.yz=p.zy;
    if(p.x < p.y)p.xy=p.yx;
    float s=1.;
    for(int i=0;i<6;i++){
      p=abs(p);
      float r=2./clamp(dot(p,p),.1,1.);
      s*=r; p*=r; p-=vec3(.6,.6,3.5);
    }
    float a=1.5;
    p-=clamp(p,-a,a);
    return length(p)/s;
  }

vec3 hsv2rgb(const in vec3 c)
{
    const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

#define user_itercount int(fInter)

vec3 mandel_iq_col(in vec3 p)
{
	vec3 zz = p;
    float m = dot(zz,zz);

    vec4 trap = vec4(abs(zz.xyz),m);
	float dz = 1.0;
    
    
	for( int i=0; i<user_itercount; i++ )
    {
		if( m > 4.0 ) break;
#if 1
        float m2 = m*m;
        float m4 = m2*m2;
		dz = 8.0*sqrt(m4*m2*m)*dz + 1.0;

        float x = zz.x; float x2 = x*x; float x4 = x2*x2;
        float y = zz.y; float y2 = y*y; float y4 = y2*y2;
        float z = zz.z; float z2 = z*z; float z4 = z2*z2;

        float k3 = x2 + z2;
        float k2 = inversesqrt( k3*k3*k3*k3*k3*k3*k3 );
        float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
        float k4 = x2 - y2 + z2;

        zz.x = p.x +  64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2;
        zz.y = p.y + -16.0*y2*k3*k4*k4 + k1*k1;
        zz.z = p.z +  -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2;
#else
		dz = 8.0*pow(m,3.5)*dz + 1.0;
        
        float r = length(zz);
        float b = 8.0*acos( clamp(zz.y/r, -1.0, 1.0));
        float a = 8.0*atan( zz.x, zz.z );
        zz = p + pow(r,8.0) * vec3( sin(b)*sin(a), cos(b), sin(b)*cos(a) );
#endif        
        
        trap = min( trap, vec4(abs(zz.xyz),m) );
        m = dot(zz,zz);
    }
    //trap.x = m;
	vec3 col;
	vec3 basecol = hsv2rgb(vec3(length(p)*5, 0.3,0.8));
	col = basecol;
	col = mix( col, vec3(0.7,0.2,0.2), 2*trap.w );
	col = mix( col, vec3(1.0,0.5,0.2), sqrt(trap.y) );
	col = mix( col, vec3(1.0,1.5,1.0)*basecol, trap.z );
	col = mix( col, vec3(1.0,1.0,1.0), sqrt(trap.x) );
	//col = mix( col, basecol , sqrt(trap.x));
    return col;
}

vec3 color(in vec3 p, in vec3 v)
{
	if(p.z < -1 || length(p) > 4) return vec3(0.8);
	return mandel_iq_col(p.xzy);
}

float mandel_iq( in vec3 p )
{
    vec3 zz = p;
    float m = dot(zz,zz);

	float dz = 1.0;
    
    
	for( int i=0; i< user_itercount; i++ )
    {
	if( m > 4.0 )
            break;
#if 1
        float m2 = m*m;
        float m4 = m2*m2;
		dz = 8.0*sqrt(m4*m2*m)*dz + 1.0;

        float x = zz.x; float x2 = x*x; float x4 = x2*x2;
        float y = zz.y; float y2 = y*y; float y4 = y2*y2;
        float z = zz.z; float z2 = z*z; float z4 = z2*z2;

        float k3 = x2 + z2;
        float k2 = inversesqrt( k3*k3*k3*k3*k3*k3*k3 );
        float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
        float k4 = x2 - y2 + z2;

        zz.x = p.x +  64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2;
        zz.y = p.y + -16.0*y2*k3*k4*k4 + k1*k1;
        zz.z = p.z +  -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2;
#else
		dz = 8.0*pow(m,3.5)*dz + 1.0;
        
        float r = length(zz);
        float b = 8.0*acos( clamp(zz.y/r, -1.0, 1.0));
        float a = 8.0*atan( zz.x, zz.z );
        zz = p + pow(r,8.0) * vec3( sin(b)*sin(a), cos(b), sin(b)*cos(a) );
#endif        

        m = dot(zz,zz);
    }

    return 0.25*log(m)*sqrt(m)/dz;
}

/* float de( in vec3 p)
{
	return mandel_iq(p.xzy);
}  */

float scene(vec3 p){
    return de(p);
    /* return smin(
        sphereSDF(p, vec3(0,sin(iTime * 3),10),1),
        sphereSDF(p, vec3(3,0,10),2),
        1
    ); */
    /* return smin(
        de(p),
        sphereSDF(p,vec3(0,0,sin(iTime)*3)*1.2,0.02),
        1.0
    ); */
}

vec3 calcNormal(vec3 pos){
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
	return normalize( e.xyy*scene( pos + e.xyy ).x + 
		e.yyx*scene( pos + e.yyx ).x + 
		e.yxy*scene( pos + e.yxy ).x + 
		e.xxx*scene( pos + e.xxx ).x );
}

vec3 worldColour(vec3 rd){
    return vec3(0.02,0.02,0.05) * ( max(0.05,dot(rd, vec3(0,2,0))) );
}

vec3 calcDiffuse(vec3 p,vec3 nrm, vec3 rd){
    vec3 light_position = vec3(-4.0, 4.0, 4.0);
    vec3 direction = normalize(light_position - p);

    float diffuse = max(0.0, dot(direction,nrm)) * 1.6 + 0.2;
    return vec3(0.4) * diffuse + worldColour(rd);
}

struct RGBMaterial {
    /// Emissive component.
    vec4 ke;
    /// Ambient component.
    vec4 ka;
    /// Diffuse component.
    vec4 kd;
    /// Specular component.
    vec4 ks;
    /// Shiness.
    float sh;
};

struct DirectionalRGBLight {
    /// Light direction.
    vec3 direction;
    /// Light rgb color.
    vec4 color;
};

vec4 calcPhong( RGBMaterial surfaceMaterial, DirectionalRGBLight light, vec3 viewPosition, vec3 normalInterp, vec3 vertPos) {
    //Calculate light direction and view direction.
    vec3 lightDirection = normalize(light.direction);
    vec3 viewDirection = normalize(viewPosition - vertPos);
    
    //Cosine theta diffuse lambertian component.
    float cosTheta = max(0.0, dot(normalInterp, normalize(lightDirection)));
    
    vec4 emissive = surfaceMaterial.ke * light.color;
    vec4 ambient = surfaceMaterial.ka * light.color;
    vec4 diffuse = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 specular = vec4(0.0, 0.0, 0.0, 1.0);
    
    //Only if light is visible from the surface point.
    if(cosTheta > 0.0) {
        
        //Reflection vector around normal.
        vec3 reflectionDirection = reflect(-lightDirection, normalInterp);
        
        //Diffuse component.
        diffuse = surfaceMaterial.kd * light.color * cosTheta;
        
        //Specular component.
        specular = surfaceMaterial.ks * light.color * pow(max(0.0, dot(reflectionDirection, viewDirection)), surfaceMaterial.sh);
    }
    return emissive + ambient + diffuse + specular;
}

float calcAO(vec3 point, vec3 normal, float step_dist, float step_nbr)
{
    float occlusion = 1.0;
    while(step_nbr > 0.0){
        occlusion -= pow(step_nbr * step_dist - (scene( point + normal * step_nbr * step_dist)),2) / step_nbr;
        step_nbr--;
    }

    return occlusion;
}

const vec3 fogColour = vec3(0.0,0.0,0.0); // vec3(0.5,0.6,0.7);

vec3 calcFog( in vec3  rgb,       // original color of the pixel
               in float distance) // camera to point distance
{
    float fogAmount = 1.0 - exp( -distance /* * 0.05 */ );
    return mix( rgb, fogColour, fogAmount );
}

vec3 march(vec2 fragCoord){
    vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.y * vec2(iAspect,1);

    vec3 ro = (cMatrix * vec4(0,0,0,1)).xyz; // vec3(0.0, 0.0, 0.0);

    const float fl = cFocal; // focal length (fov)
    vec3 rd = (cMatrix * vec4(normalize( vec3(uv,fl) ),0)).xyz;

    const float near = 0.000001;
    const float far  = 10000;

    float ray_distance = 0.0;

    RGBMaterial material = {
        vec4( 0.0, 0.0, 0.0, 1.0),
        vec4( 0.4, 0.4, 0.4, 1.0),
        vec4( 0.3, 0.2, 0.4, 1.0),
        vec4( 0.9, 0.9, 0.9, 1.0),
        800
    };

    DirectionalRGBLight light = {
        vec3(4,2,-1),
        vec4(0.6,0.6,0.6,1.0)
    };

    const int max_march = 1024;
    for(int i = 0; i < max_march; i++){
        vec3 p = ro + rd * ray_distance;
        float min_distance = scene(p);

        if(min_distance < near){
            //return calcDiffuse(p,calcNormal(p),rd);
            // return calcNormal(p);
            vec3 nrm = calcNormal(p);
            vec3 colour = calcPhong(
                material,
                light,
                rd,
                nrm,
                p
            ).rgb + pow(calcAO(p,nrm,0.015,20),100) * 0.4;

            return calcFog(colour,ray_distance); // color(p,vec3(1,0,1));

        }else if(min_distance > far){
            break;
        }

        ray_distance += min_distance;
    }
    return fogColour; //worldColour(rd);
}

vec3 fromLinear(vec3 linearRGB)
{
    bvec3 cutoff = lessThan(linearRGB.rgb, vec3(0.0031308));
    vec3 higher = vec3(1.055)*pow(linearRGB.rgb, vec3(1.0/2.4)) - vec3(0.055);
    vec3 lower = linearRGB.rgb * vec3(12.92);

    return mix(higher, lower, cutoff);
}

void main() {
    vec3 accum = march(uv * iResolution);

    /* //HDR
    accum = accum / (accum+ vec3(1.0));
    //Gamma
    float gamma = 1.1;
    accum = pow(accum, vec3(1.0/gamma)); */

    frag_color.xyz = fromLinear(accum); // pow( march(uv * iResolution), vec3(0.8545) );
    frag_color.w   = 1.0;
}
@end

@program march vs fs