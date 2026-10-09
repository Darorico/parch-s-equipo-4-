// Hoja de papel blanco arrugado y doblado, generada por código (no necesita imágenes).
// Las arrugas son facetas de un patrón de Voronoi con distinto sombreado; los dobleces son dos
// líneas en el centro de la hoja; el grano es ruido por píxel.
shader_type canvas_item;

uniform vec4 color_papel : source_color = vec4(0.984, 0.980, 0.965, 1.0);
uniform float escala_arrugas = 3.0;
uniform float fuerza_arrugas = 0.022;
uniform float fuerza_grano = 0.018;
uniform float fuerza_dobleces = 0.035;
// Proporción ancho/alto del rectángulo (la actualiza fondo_papel.gd) para que las arrugas no se estiren.
uniform vec2 proporcion = vec2(1.0, 1.0);

vec2 azar2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float azar1(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// x: distancia al borde de la faceta, yz: identificador de la faceta.
vec3 voronoi(vec2 x) {
	vec2 n = floor(x);
	vec2 f = fract(x);
	float f1 = 8.0;
	float f2 = 8.0;
	vec2 id = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 r = g + azar2(n + g) - f;
			float d = dot(r, r);
			if (d < f1) {
				f2 = f1;
				f1 = d;
				id = n + g;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	return vec3(sqrt(f2) - sqrt(f1), id);
}

void fragment() {
	vec2 uv = UV * proporcion;
	vec3 grande = voronoi(uv * escala_arrugas);
	vec3 chica = voronoi(uv * escala_arrugas * 2.3 + 7.0);
	float facetas = (azar1(grande.yz) - 0.5) * fuerza_arrugas + (azar1(chica.yz) - 0.5) * fuerza_arrugas * 0.5;
	// Arrugas: cada faceta con su propia luz, y una línea fina y suave en algunos de sus bordes.
	float aristas = (1.0 - smoothstep(0.0, 0.025, grande.x)) * 0.012 * step(0.55, azar1(grande.yz + 3.1));

	float doblez_v = 1.0 - smoothstep(0.0, 0.003, abs(UV.x - 0.5));
	float doblez_h = 1.0 - smoothstep(0.0, 0.003, abs(UV.y - 0.5));
	float lado = (UV.x < 0.5 ? 0.008 : -0.006) + (UV.y < 0.5 ? 0.004 : -0.004);

	float grano = (azar1(floor(FRAGCOORD.xy)) - 0.5) * fuerza_grano;
	vec3 color = color_papel.rgb + facetas - aristas + lado + grano - (doblez_v + doblez_h) * fuerza_dobleces;
	COLOR = vec4(color, 1.0);
}
