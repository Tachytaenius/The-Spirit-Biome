extern number erodeResolution;
extern number erodeDistance;
const vec2 size = vec2(384, 256);
vec4 effect(vec4 colour, Image texture, vec2 textureCoords, vec2 windowCoords) {
	vec4 colour2 = Texel(texture, textureCoords);
	for (number x = -erodeResolution; x < erodeResolution; ++x) {
		for (number y = -erodeResolution; y < erodeResolution; ++y) {
			vec2 current = vec2(x, y) / erodeResolution;
			number relevance = max(1 - length(current), 0);
			colour2 = relevance * min(Texel(texture, textureCoords + erodeDistance * current / size), colour2) + (1 - relevance) * colour2;
		}
	}
	return colour * colour2;
}
