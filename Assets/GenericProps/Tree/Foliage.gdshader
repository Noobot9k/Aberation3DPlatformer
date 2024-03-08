shader_type spatial;

uniform sampler2D TEXTURE;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	
	vec4 sampledTexture = texture(TEXTURE, UV);
	
	ALPHA_SCISSOR_THRESHOLD = .5;
	ALBEDO = vec3(sampledTexture.r, sampledTexture.g, sampledTexture.b);
	ALPHA = sampledTexture.a;
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
