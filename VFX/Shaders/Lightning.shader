shader_type canvas_item;

uniform sampler2D mask;
uniform vec4 color : hint_color;
uniform float thickness : hint_range(0, 0.99, 0.01) = 0.1;
uniform float verticalThinning : hint_range(0, 3, 0.005) = 0.01;
uniform vec4 glow : hint_color;
uniform float brightness : hint_range(0, 5, 0.1) = 1;
uniform float sampleLength : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float sampleOffset : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform bool distortion = false;
uniform float distortionIntensity : hint_range(0.0, 2.0, 0.01) = 0.1;
uniform float distortionCycles : hint_range(0.0, 40.0, 1.0) = 10.0;
uniform float distortionSpeed : hint_range(0.0, 50.0, 1) = 10;

void fragment() {
	float x = UV.x;
	if(distortion) {
		x += distortionIntensity*sin(distortionCycles*UV.y+TIME*distortionSpeed);
	}
	vec2 translatedUV = vec2(x, mod(sampleLength*UV.y - sampleOffset, 1.0));
	COLOR = color*step(1.0-thickness + pow(verticalThinning*(abs(0.5-UV.y)), 3), texture(mask, translatedUV)).r;
	COLOR.rgb += glow.rgb * brightness;
} 