precision highp float;
uniform vec2 u_resolution; // Width & height of the shader
uniform float u_time; // Time elapsed
uniform mat4 camera;
uniform vec2 S1;
uniform float BF;
uniform int Scene;
uniform int Noise;
uniform vec3 camPos;
uniform vec3 camRot;
// Constants
#define PI 3.1415925359
#define TWO_PI 6.2831852
#define MAX_STEPS 10000 // Max Raymarching steps
#define MAX_DIST 10000. // Max Raymarching distance
#define SURF_DIST 0.0001 // Surface Distance
#define OUTLINE_DIST 0.0001

float hash(float n) { return fract(sin(n) * 753.5453123); }

float snoise(vec3 x)
{
	vec3 p = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	float n = p.x + p.y * 157.0 + 113.0 * p.z;
	return mix(mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
	mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y),
	mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
	mix(hash(n + 270.0), hash(n + 271.0), f.x),
	f.y), f.z);
}
float noise(vec3 position, int octaves, float frequency, float
persistence) {
	float total = 0.0;
	float maxAmplitude = 0.0;
	float amplitude = 1.0;
	for (int i = 0; i < octaves; i++) {
		total += snoise(position * frequency) * amplitude;
		frequency *= 2.0;
		maxAmplitude += amplitude;
		amplitude *= persistence;
	}
	return total / maxAmplitude;
}


//float outline;
float distance;
float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

float sdTorus( vec3 p, vec2 t )
{
	vec2 q = vec2(length(p.xz)-t.x,p.y);
	return length(q)-t.y;
}


float sdBox(vec3 p, vec3 b )
{
	vec3 q = abs(p) - b;
	return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float GetDist(vec3 p)
{
	vec4 s = vec4(S1.x,S1.y,5,1.0); //Sphere xyz is position w is radius
	vec4 s1= vec4(0,0,20,10);


	float sphereDist = length(p-s.xyz) - s.w ;
	//s
	float sphereDist2 = length(p-s1.xyz) - s1.w ;
	if(Noise == 1)
	sphereDist += sin(4.0 * p.x) * sin(u_time + p.y * 4.0) * sin(4.0* p.z) * .25;
	float planeDist  = p.y;
	float rectDistance = sdBox(p-vec3(0.5,0.2,6.0), vec3(1.0,1.0 ,1.0));
	float d = smin(sphereDist, rectDistance, BF);

	return d;
}



float RayMarch(vec3 ro, vec3 rd)
{
	float dO = 0.; //Distane Origin
	float ans = 0.0;
	for(int i=0;i<MAX_STEPS;i++)
	{
		//ans+=.01;
		vec3 p = ro + rd * dO;
		float ds = GetDist(p); // ds is Distance Scene
		dO += ds;
		ans+=0.01;
		if(ds < OUTLINE_DIST ){
			//ans = 1.0;
		}
		if(ds < SURF_DIST){
			ans =0.0;
		}
		if(dO > MAX_DIST || ds < SURF_DIST){
			//ans =0.0;
			break;
		}

	}
	return  pow(ans, 2.);
}

float RayMarch2(vec3 ro, vec3 rd)
{
	float dO = 0.; //Distane Origin
	for(int i=0;i<MAX_STEPS;i++)
	{
		vec3 p = ro + rd * dO;
		float ds = GetDist(p); // ds is Distance Scene
		dO += ds;
		if(dO > MAX_DIST || ds < SURF_DIST)
		break;
	}
	return dO;
}

float RayMarch3(vec3 ro, vec3 rd)
{
	float ans = 0.;
	float dO = 0.; //Distane Origin
	for(int i=0;i<MAX_STEPS;i++)
	{
		vec3 p = ro + rd * dO;
		float ds = GetDist(p); // ds is Distance Scene
		if(ds<SURF_DIST){
			dO += 0.001;
			ans += pow((SURF_DIST-ds), 0.2)/(1000.);
		} else {
			dO += ds;
		}
		if(dO > MAX_DIST)
		break;
	}
	return clamp(pow(ans, 1.)/5., 0, 1);
}


float f(vec2 p){
	//return  -5.0+(sin(p.x)+sin(p.y));
	return -5.0+(5.0*noise(vec3(p.x,p.y,0),5, .1, 1.0))+noise(vec3(p.x,p.y,0),5, 1.0, 1.0);
}

float f(float px, float py){
	return  f(vec2(px, py));
}

float RayMarchTerrain(vec3 ro, vec3 rd){
	float dt = 0.1;
	const float mint = 0.1;
	const float maxt = 10.0;
	float lh = 0.0;
	float ly = 0.0;
	float resT = 0.0;

	for( float t = mint; t < maxt; t += dt )
	{
		vec3  p = ro + rd*t;
		float h = f(p.xz);
		if( p.y < h )
		{
			// interpolate the intersection distance
			resT = t - dt + dt*(lh-ly)/(p.y-ly-h+lh);
			return resT;
		}
		// allow the error to be proportinal to the distance
		dt = 0.01*t;
		lh = h;
		ly = p.y;
	}
	return resT;
}



vec3 GetNormal(vec3 position)
{
	float distance = GetDist(position);
	vec2 epsilon = vec2(.01,0);
	vec3 n = distance - vec3(

	GetDist(position-epsilon.xyy), //X Component
	GetDist(position-epsilon.yxy), //Y Component
	GetDist(position-epsilon.yyx)  //Z Component

	);

	return normalize(n);
}
float GetLight(vec3 p)
{
	// Directional light
	vec3 lightPos = vec3(5.0*sin(2.*2.),4,0.0); // Light Position
	vec3 l = normalize(lightPos-p);
	vec3 n = GetNormal(p);

	float dif = dot(n,l);
	dif += .1;
	dif = clamp(dif,0.,1.);

	float d = RayMarch2(p+n*SURF_DIST*2., l);
	if(d<length(lightPos-p)) dif *= .1;
	return dif;
}

void main()
{
	vec2 uv = (gl_FragCoord.xy-.5*u_resolution.xy)/u_resolution.y;
	vec3 ro = vec3(0,0,0);
	vec3 rd = normalize(vec3(uv.x,uv.y,1));
	float d1 = RayMarch2(ro,rd);
	float d = RayMarch3(ro,rd);
	vec3 p = ro + rd * d1;
	float dif = GetLight(p);
	vec3 color = vec3(0);
	if(Scene != 3)
	color = vec3(0.0, 0.5, 1.0)*vec3(dif);
	if(Scene == 2)
	color =vec3(0.9, 0.9, 0.9)- vec3(d*2.);
	float outline = RayMarch(ro, rd);
	color.x += outline;
	color.y += outline;
	color.z += outline;
	gl_FragColor = vec4(color,1.0);
}