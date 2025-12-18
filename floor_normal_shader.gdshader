shader_type canvas_item;

// Shader que genera normal map procedural para simular volumen en el suelo
// Las luces 2D reaccionarán a estas normales dando profundidad

uniform float tile_scale : hint_range(0.01, 1.0) = 0.1;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.8;
uniform float edge_highlight : hint_range(0.0, 1.0) = 0.3;

// Genera ruido simple para variación
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	vec4 tex_color = texture(TEXTURE, uv);

	// Calcular normales basadas en diferencias de luminosidad
	float pixel_size = 0.002;
	float left = dot(texture(TEXTURE, uv - vec2(pixel_size, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
	float right = dot(texture(TEXTURE, uv + vec2(pixel_size, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
	float up = dot(texture(TEXTURE, uv - vec2(0.0, pixel_size)).rgb, vec3(0.299, 0.587, 0.114));
	float down = dot(texture(TEXTURE, uv + vec2(0.0, pixel_size)).rgb, vec3(0.299, 0.587, 0.114));

	// Gradiente para normal map
	float dx = (right - left) * normal_strength;
	float dy = (down - up) * normal_strength;

	// Agregar ruido sutil para textura
	float n = noise(uv * 100.0 * tile_scale) * 0.1;
	dx += n * 0.5;
	dy += n * 0.5;

	// Convertir a normal (rango 0-1 para NORMAL_MAP)
	vec3 normal = normalize(vec3(dx, dy, 1.0));
	normal = normal * 0.5 + 0.5;

	// Aplicar al output
	COLOR = tex_color;
	NORMAL_MAP = vec4(normal, 1.0);
	NORMAL_MAP_DEPTH = normal_strength;
}
