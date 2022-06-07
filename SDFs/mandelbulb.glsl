#define user_itercount int(fInter)

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

float de( in vec3 p)
{
	return mandel_iq(p.xzy);
} 