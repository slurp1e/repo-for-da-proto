shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float vignette_strength : hint_range(0.0, 2.0) = 0.6;
uniform float vignette_size : hint_range(0.0, 1.0) = 0.35;
uniform float saturation : hint_range(0.0, 2.0) = 0.75;
uniform vec3 color_tint : source_color = vec3(0.78, 0.88, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.18;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.04;
uniform float aberration : hint_range(0.0, 0.02) = 0.003;

void fragment() {

	vec2 uv = SCREEN_UV;
	vec2 offset = vec2(aberration, 0.0);

	// ── Chromatic aberration ──
	float r = texture(SCREEN_TEXTURE, uv + offset).r;
	float g = texture(SCREEN_TEXTURE, uv).g;
	float b = texture(SCREEN_TEXTURE, uv - offset).b;

	vec3 col = vec3(r, g, b);

	// ── Saturation ──
	float gray = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(gray), col, saturation);

	// ── Color tint ──
	col = mix(col, col * color_tint, tint_strength);

	// ── Vignette ──
	vec2 center = uv - 0.5;
	float dist = length(center);

	float vignette = smoothstep(vignette_size, vignette_size + 0.5, dist);
	col *= 1.0 - vignette * vignette_strength;

	// ── Scanlines ──
	float scan = sin(uv.y * 800.0) * 0.5 + 0.5;
	col -= scan * scanline_strength;

	COLOR = vec4(col, 1.0);
}
