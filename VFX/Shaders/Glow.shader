shader_type canvas_item;

uniform vec4 color : hint_color = vec4(1.0,1.0,1.0,1.0);
uniform vec4 glow : hint_color = vec4(1.0,1.0,1.0,1.0);
uniform float brightness : hint_range(0, 10, 0.1) = 1;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.a = COLOR.r*COLOR.r;
	COLOR *= color;
	COLOR.rgb += brightness*glow.rgb;
}
