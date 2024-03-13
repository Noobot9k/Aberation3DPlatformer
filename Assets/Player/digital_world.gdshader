shader_type spatial;

uniform sampler2D BackBufferCopy : hint_screen_texture;
//uniform sampler2D depth_texture : source_color, hint_depth_texture;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = NORMAL; // texture(BackBufferCopy, SCREEN_UV).xyz * .9;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
