shader_type canvas_item;

uniform vec4 color : hint_color = vec4(0.48,0.48,0.48,1);
uniform vec4 glow : hint_color = vec4(1,0.39,0,1);
uniform float brightness : hint_range(0, 4, 0.1) = 1.3;
uniform float alphaMultiplier : hint_range(0, 5, 0.1) = 1.5;
uniform sampler2D simplexNoise;
uniform float simplexScrollSpeed : hint_range(0, 4, 0.1) = 1;
uniform float simplexDistortion: hint_range(0, 2, 0.1) = 1.2;
uniform sampler2D simplexNoise2;
uniform float simplexScrollSpeed2 : hint_range(0, 4, 0.1) = 0.4;


void fragment() {
	float simplexValue = texture(simplexNoise, vec2(UV.x, UV.y+TIME*simplexScrollSpeed)).r;
	vec2 distortion = simplexDistortion*(1.0-UV.y)*(vec2(simplexValue)-0.5);
	float simplexValue2 = texture(simplexNoise2, vec2(UV.x*0.5, UV.y*0.5+TIME*simplexScrollSpeed2)).r;
	COLOR = texture(TEXTURE, (UV+distortion));
	COLOR.a = min(1, COLOR.r*alphaMultiplier);
	COLOR *= 1.0-pow(simplexValue2, 2);

	COLOR *= color;
	COLOR.rgb += brightness*glow.rgb;
}