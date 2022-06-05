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
    float IAspect;
    float iTime;
};

in vec2 uv;
out vec4 frag_color;

vec3 circ2d(vec2 vv, float size){
    return length(vv) < size ? vec3(1) : vec3(0);
}

float sphereSDF(vec3 p, vec3 c, float r){
    return length(p - c) - r;
}

float scene(vec3 p){
    return sphereSDF(p, vec3(0,sin(iTime * 3),10),2);
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

vec3 march(vec2 fragCoord){
    vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.y * vec2(IAspect,1);

    vec3 ro = vec3(0.0, 0.0, -1.0);

    const float fl = 2.5; // focal length (fov)
    vec3 rd = normalize( vec3(uv,fl) );

    const float near = 0.001;
    const float far  = 1000;

    float ray_distance = 0.0;

    const int max_march = 12;
    for(int i = 0; i < max_march; i++){
        vec3 p = ro + rd * ray_distance;
        float min_distance = scene(p);

        if(min_distance < near){
            return calcDiffuse(p,calcNormal(p),rd);
        }else if(min_distance > far){
            break;
        }

        ray_distance += min_distance;
    }
    return worldColour(rd);
}

vec3 fromLinear(vec3 linearRGB)
{
    bvec3 cutoff = lessThan(linearRGB.rgb, vec3(0.0031308));
    vec3 higher = vec3(1.055)*pow(linearRGB.rgb, vec3(1.0/2.4)) - vec3(0.055);
    vec3 lower = linearRGB.rgb * vec3(12.92);

    return mix(higher, lower, cutoff);
}

void main() {
    frag_color.xyz = fromLinear(march(uv * iResolution)); // pow( march(uv * iResolution), vec3(0.8545) );
    frag_color.w   = 1.0;
}
@end

@program march vs fs