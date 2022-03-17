
#version 330 core
precision highp float;
uniform vec2 u_resolution; // Width & height of the shader
uniform float u_time; // Time elapsed
uniform mat4 camera;
uniform vec2 S1;
uniform float BF;
uniform float CF;
uniform vec3 camPos;
uniform mat4 M;
uniform vec3 camRot;
uniform sampler2D tex;
out vec4 color;
// Constants
#define PI 3.1415925359
#define TWO_PI 6.2831852
#define MAX_STEPS 1000 // Mar Raymarching steps
#define MAX_DIST 100. // Max Raymarching distance
#define SURF_DIST 0.02 // Surface Distance
#define OUTLINE_DIST 0.02

float hash(float n) { return fract(sin(n) * 753.5453123); }

float snoise( vec3 x )
{
	vec3 p = floor(x);
	vec3 f = fract(x);

	f = f*f*(3.0-2.0*f);
	float n = p.x + p.y*57.0 + 113.0*p.z;

	return mix(mix(mix( hash(n+0.0), hash(n+1.0),f.x),
	mix( hash(n+57.0), hash(n+58.0),f.x),f.y),
	mix(mix( hash(n+113.0), hash(n+114.0),f.x),
	mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
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

float distance;
float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

float fbm( vec2 x, float H, int octaves)
{
	float t = 0.0;
	for( int i=0; i<octaves; i++ )
	{
		float f = pow( 5.0, float(i) );
		float a = pow( f, -H );
		t += 2/CF*a*snoise(vec3(CF*0.1*x.x, CF*0.1*x.y, 0.0)*f);
	}
	return t;
}

float f(vec2 p, float distance){
	//return  2+3*(sin(p.x)+sin(p.y));
	//return snoise(vec3(p.x, p.y, 0));
	return 5.0*fbm(p, 1.0, int(5.0));
	//return 2.0*fbm(p, 1.0, int(4.0)-int(log(pow(distance,0.4))));

	//return -5.0+(5.0*noise(vec3(p.x,p.y,0),2, .1, 1.0))+noise(vec3(p.x,p.y,0),2, 1.0, 1.0);
	//return  + (.6 * texture(tex, p.xy/(50.0)).r) + (5*texture(tex, p.xy/(500.0)).b);
	//return (0.2 * texture(tex, p.xy/(100.0)).r) +(3*texture(tex, p.xy/(1000.0)).b);
}

float f(float px, float py){
	return  f(vec2(px, py),2);
}

vec4 RayMarchTerrain(vec3 ro, vec3 rd){
	float outline=0;
	float dt = 0.2;
	const float mint = 0.01;
	float maxt =BF*100;
	float lh = 0.0;
	float ly = 0.0;
	float resT = 0.0;

	for( float t = mint; t < maxt; t += dt )
	{
		outline += 0.01;
		vec3  p = ro + rd*t;
		if(p.y > max(camPos.y,20.0)){
			return vec4(0,0,0,1002);
		}
		float h = f(p.xz, t);
		if( p.y < h )
		{
			resT = t - dt + dt*(lh-ly)/(p.y-ly-h+lh);

			return vec4(0,0,pow(outline/resT, 2),resT);
		}
		dt = 0.05*pow(t, 0.15);
		lh = h;
		ly = p.y;
	}
	return vec4(0,0,0,100000);
}

vec4 RayMarchTerrain2(vec3 ro, vec3 rd){
	float outline=0;
	float dt = 0.2;
	const float mint = 0.01;
	float maxt = 200;
	float lh = 0.0;
	float ly = 0.0;
	float resT = 0.0;

	for( float t = mint; t < maxt; t += dt )
	{
		outline += 0.01;
		vec3  p = ro + rd*t;
		float h = f(p.xz, t);
		if(p.y > 20.0){
			return vec4(0,0,0,1002);
		}

		if( p.y < h )
		{
			// interpolate the intersection distance
			resT = t - dt + dt*(lh-ly)/(p.y-ly-h+lh);

			return vec4(0,0,pow(outline/resT, 2),resT);
		}
		// allow the error to be proportinal to the distance
		dt = .1*pow(t, 1);
		lh = h;
		ly = p.y;
	}
	return vec4(0,0,0,1002);
}

vec3 GetNormal(vec3 p){
//	float eps =0.01*pow(2,length(camPos-p)/5);
float eps = 0.001;
	return normalize( vec3( f(p.x-eps,p.z) - f(p.x+eps,p.z),
	2.0*eps,
	f(p.x,p.z-eps) - f(p.x,p.z+eps) ) );
}

float softshadow(vec3 ro, vec3 rd, float mint, float maxt, float k )
{
	float res = 1.0;
	float ph = 1e20;
	for( float t=mint; t<maxt; )
	{
		vec3  p = ro + rd*t;
		float h = f(p.xz, t);
		if( h<0.01 )
		return 0.0;
		float y = h*h/(2.0*ph);
		float d = sqrt(h*h-y*y);
		res = min( res, k*d/max(0.0,t-y) );
		ph = h;
		t += h;
	}
	return res;
}
vec4 GetLight(vec3 p)
{
	// Directional light
	vec3 lightPos = vec3(800+camPos.x, 300.0, 600+camPos.z); // Light Position

	vec3 l = normalize(lightPos-p); // Light Vector

	vec3 n = GetNormal(p); // Normal Vector

	float dif = dot(n,l); // Diffuse light
	dif += .1;
	dif = clamp(dif,0.,1.); // Clamp so it doesnt go below 0

	// Shadows
	float d = RayMarchTerrain2(p+n*0.1*2.,l).w;
	//float d = softshadow(p+n*0.1*2.,l, .01,20, 10);
	//dif *= pow(softshadow(p+n*0.1*2.,l, .01, 40.0, 20.0), 2.0);

	if(d<20){
		dif =0;
	}
	//dif *=d;
//	dif *= pow(softshadow(p+n*0.1*2.,l, .01, 40.0, 20.0), 2.0);
	return vec4(n,dif);
}



vec3 rayDirection(float fieldOfView, vec2 res, vec2 fragCoord) {
	vec2 xy = fragCoord - res / 2.0;
	float z = res.y / tan(radians(fieldOfView) / 2.0);
	return normalize(vec3(xy, -z));
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
	// Based on gluLookAt man page
	vec3 f = normalize(center - eye);
	vec3 s = normalize(cross(f, up));
	vec3 u = cross(s, f);
	return mat4(
	vec4(s, 0.0),
	vec4(u, 0.0),
	vec4(-f, 0.0),
	vec4(0.0, 0.0, 0.0, 1)
	);
}




void main()
{


	vec3 viewDir = rayDirection(45.0, u_resolution.xy, gl_FragCoord.xy);

	vec3 eye = camPos;
	vec3 looking = (vec4(0.0, 0.0, 1.0, 1.0) * M).xyz;
	mat4 viewToWorld = viewMatrix(eye, eye+looking, vec3(0.0, 1.0, 0.0));


	vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
	//color = vec4(1+normalize(worldDir.rgb), 1.0);
	//return;

	//float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
	vec4 result = RayMarchTerrain(eye, worldDir);
	float d = result.w;
	if(d > 90000){
		d = 100*BF;
	}
	float outline = result.z;

	vec3 p = eye + worldDir * d;
	color = vec4(1.0, 0.0, 1.0, 1.0);

	// The closest point on the surface to the eyepoint along the view rayrrrrrrrrrrrr
	vec4 lighting = GetLight(p);// Diffuse lighting
	lighting.xyz += lighting.xyz/abs(lighting.xyz) * snoise(p*10);
	lighting.xyz += 0.2*lighting.xyz/abs(lighting.xyz) * snoise(p*50);
	float dif = lighting.w;
	float delta = pow(acos(dot(vec3(0,-1,0), lighting.xyz)/length(lighting.xyz)),1)/5;

	delta = abs(delta);
	vec3 tcol;
	if(delta > 0.45){
		tcol = vec3(1,1,1)- delta;
	} else {
		tcol = delta * mix(vec3(0.6,0.4,0.4), vec3(0.5,0.4,0.4), snoise(p*10));
	}



	tcol*=dif;
	//float fogAmount = 0.3*exp(-eye.y*(.10/BF)) * (1.0-exp(-d*worldDir.y*(0.1/BF)))/worldDir.y;
	float fogAmount = 1.0 - exp( -d*.040/BF );
	fogAmount += (0.1) * exp(-eye.y/2.0) * (1.0-exp( -d*worldDir.y/2.0))/worldDir.y;
	float sunAmount = max(dot(worldDir, normalize(vec3(0, -1.0, 5.0))), 0.0);
	//sunAmount = dif;
	vec3  fogColor  = mix(vec3(0.5, 0.6, 0.7), // bluish
	vec3(1.0, 0.9, 0.7), // yellowish
	pow(sunAmount, 8.0));
	tcol =  mix(tcol, fogColor, fogAmount);
	if(d > 90000){
		tcol = fogColor;
	}
	color.rgb = tcol;
}
//
//	gl_FragColor = vec4(tcol,1.0);
//}