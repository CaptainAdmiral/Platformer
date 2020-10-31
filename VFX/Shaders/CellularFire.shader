shader_type canvas_item;

uniform vec4 color : hint_color = vec4(0.48,0.48,0.48,1);
uniform vec4 glow : hint_color = vec4(1,0.39,0,1);
uniform float brightness : hint_range(0, 4, 0.1) = 1;
uniform float alphaMultiplier : hint_range(0, 5, 0.1) = 1;
uniform sampler2D simplexNoise;
uniform float simplexScrollSpeed : hint_range(0, 4, 0.1) = 1;
uniform float simplexDistortion: hint_range(0, 2, 0.1) = 0.7;
uniform bool scaleDistiortionWithY = false;
uniform bool doubleSampleSimplex = false;
uniform float cellularNoiseTiling : hint_range(1, 10, 1) = 3;
uniform float cellularNoiseExponent: hint_range(0.1, 6, 0.1) = 0.4;
uniform float cellularScrollSpeed : hint_range(0, 4, 0.1) = 0.5;

vec2 random2(vec2 p) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float cellular_noise(vec2 coord) {
    vec2 i = floor(coord);
    vec2 f = fract(coord);
	
	float minDist = 100000000.0;
	for(float x=-1.0; x<=1.0; x++) {
		for(float y=-1.0; y<=1.0; y++) {
			vec2 node = random2(i + vec2(x,y)) + vec2(x,y);
			minDist = min(minDist, sqrt((f-node).x * (f-node).x + (f-node).y * (f-node).y));
		}
	}
	return minDist;
}

void fragment() {
	float simplexValue = texture(simplexNoise, vec2(UV.x, UV.y+TIME*simplexScrollSpeed)).r;
	float distortionScale = 1.0;
	if(scaleDistiortionWithY) {
		distortionScale = (1.0-UV.y);
	}
	vec2 distortion = simplexDistortion*distortionScale*(vec2(simplexValue)-0.5);
	if (doubleSampleSimplex) {
		simplexValue = texture(simplexNoise, UV+distortion).r;
		distortion = simplexDistortion*distortionScale*(vec2(simplexValue)-0.5);
	}
	COLOR = texture(TEXTURE, UV+distortion);
	COLOR.a = min(1, COLOR.r*alphaMultiplier)*pow(0.5+cellular_noise((vec2(UV.y+TIME*cellularScrollSpeed, UV.x)+distortion)*cellularNoiseTiling), cellularNoiseExponent);
	COLOR *= color;
	COLOR.rgb += brightness*glow.rgb;
}