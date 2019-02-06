extern int depth;

vec4 effect(vec4 colour, Image texture, vec2 textureCoords, vec2 pixelCoords) {
	vec4 fragmentColour = Texel(texture, textureCoords);
	fragmentColour = floor(fragmentColour * (depth - 1) + 0.5) / (depth - 1);
	return fragmentColour;
}
