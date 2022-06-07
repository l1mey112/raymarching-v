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

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// @include SDFs/tubeinfinite.glsl
// @include SDFs/tubes.glsl
// @include SDFs/columns.glsl
// @include SDFs/cage.glsl
// @include SDFs/mandelbulb.glsl

@include SDFs/primitives.glsl

float scene(vec3 p){
    // return de(p);
    return opRep(p,vec3(1,1,1));
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

float calcAO(vec3 point, vec3 normal, float step_dist, float step_nbr){
    float occlusion = 1.0;
    while(step_nbr > 0.0){
        occlusion -= pow(step_nbr * step_dist - (scene( point + normal * step_nbr * step_dist)),2) / step_nbr;
        step_nbr--;
    }

    return occlusion;
}

const vec3 fogColour = vec3(0.0,0.0,0.0); // vec3(0.5,0.6,0.7);

vec3 calcFog( in vec3  rgb, in float distance){
    float fogAmount = 1.0 - exp( -distance * 0.07 );
    return mix( rgb, fogColour, fogAmount );
}

/* vec3 calcFog( in vec3  rgb,      // original color of the pixel
               in float distance, // camera to point distance
               in vec3  rayDir,   // camera to point vector
               in vec3  sunDir )  // sun light direction
{
    float fogAmount = 1.0 - exp( -distance*0.1 );
    float sunAmount = max( dot( rayDir, sunDir ), 0.0 );
    vec3  fogColor  = mix( vec3(0.3,0.3,0.3), // bluish
                           vec3(0.3,0.3,0.3), // yellowish
                           pow(sunAmount,8.0) );
    return mix( rgb, fogColor, fogAmount );
} */

vec3 march(vec2 fragCoord){
    vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.y * vec2(iAspect,1);

    vec3 ro = (cMatrix * vec4(0,0,0,1)).xyz; // vec3(0.0, 0.0, 0.0);

    const float fl = cFocal; // focal length (fov)
    vec3 rd = (cMatrix * vec4(normalize( vec3(uv,fl) ),0)).xyz;

    const float near = 0.00001;
    const float far  = 1000;

    float ray_distance = 0.0;

    RGBMaterial material = {
        vec4( 0.0, 0.0, 0.0, 1.0),
        vec4( 0.2, 0.2, 0.2, 1.0),
        vec4( 0.6, 0.6, 0.6, 1.0),
        vec4( 0.9, 0.9, 0.9, 1.0),
        200
    };

    DirectionalRGBLight light = {
        vec3(4,2,-1),
        vec4(0.6,0.6,0.6,1.0)
    };

    const int max_march = 512;
    float smallest_distance = 0.0;
    for(int i = 0; i < max_march; i++){
        vec3 p = ro + rd * ray_distance;
        float min_distance = scene(p);
        smallest_distance = min(smallest_distance,min_distance);

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

            return calcFog(colour,ray_distance); // ,rd,normalize(vec3(4,2,-1)) // color(p,vec3(1,0,1));

        }else if(min_distance > far){
            break;
        }

        ray_distance += min_distance;
    }
    return fogColour; // vec3(smallest_distance * 1000); // fogColour; // calcFog(vec3(0),ray_distance,rd,normalize(vec3(4,2,-1))); // fogColour; //worldColour(rd);
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