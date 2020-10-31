shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float displacement : hint_range(0, 0.3, 0.01) = 0.05;
uniform float radius : hint_range(0, 1, 0.05) = 0.5;
uniform float thickness : hint_range(0, 1, 0.01) = 0.05;
uniform float smoothing : hint_range(0, 0.5, 0.05) = 0.15;
uniform bool chromaticAberration = false;
uniform float colorDisplacement = 1.0;

void fragment() {
	float mask = (1.0 - smoothstep(radius-smoothing, radius, length(UV - center))) * smoothstep(radius-smoothing-thickness, radius, length(UV - center));
	vec2 disp = normalize(UV - center)*mask*displacement;
	if (chromaticAberration) {
		float len = length(UV - center);
		COLOR.r = texture(SCREEN_TEXTURE, SCREEN_UV-disp*len*colorDisplacement).r;
		COLOR.g = texture(SCREEN_TEXTURE, SCREEN_UV-disp).g;
		COLOR.b = texture(SCREEN_TEXTURE, SCREEN_UV-disp*len*(-colorDisplacement)).b;
	} else {
		COLOR = texture(SCREEN_TEXTURE, SCREEN_UV-disp);
	}
} 