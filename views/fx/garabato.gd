@tool
class_name Garabato
extends RefCounted
## Dibujo «a mano» estilo cuaderno escolar: líneas de lápiz temblorosas y rellenos de crayón rayados.
##
## Todas las funciones dibujan sobre un canvas item (RID). Así sirven igual dentro del _draw() de un
## Control (con get_canvas_item()) que dentro de un StyleBox (cuyo _draw recibe el RID).
## `semilla` hace que el mismo trazo salga siempre igual. Si se le suma Garabato.cuadro, el trazo
## «tiembla» cuadro por cuadro como un dibujo animado en stop-motion (lo avanza GestorAnimaciones).

const LAPIZ := Color("#2b2622")
## Grupo de nodos que se redibujan en cada cuadro de la animación stop-motion («línea viva»).
const GRUPO_VIVO := &"garabato_vivo"

## Cuadro actual de la animación stop-motion (lo avanza GestorAnimaciones).
static var cuadro := 0


## Línea de lápiz: se pasa un poquito de los extremos y ondula ligeramente, como hecha a mano.
static func linea(ci: RID, a: Vector2, b: Vector2, color: Color, ancho := 2.0, semilla := 0, temblor := 1.2) -> void:
	var rng := _rng(semilla)
	var largo := a.distance_to(b)
	if largo < 0.5:
		return
	var dir := (b - a) / largo
	var normal := Vector2(-dir.y, dir.x)
	var inicio := a - dir * rng.randf_range(0.0, 3.0)
	var fin := b + dir * rng.randf_range(0.0, 3.0)
	var tramos := maxi(2, int(largo / 14.0))
	var puntos := PackedVector2Array()
	for i in tramos + 1:
		var desvio := 0.0 if i == 0 or i == tramos else rng.randf_range(-temblor, temblor)
		puntos.append(inicio.lerp(fin, float(i) / tramos) + normal * desvio)
	RenderingServer.canvas_item_add_polyline(ci, puntos, PackedColorArray([color]), ancho, true)


## Contorno de un rectángulo con cuatro trazos independientes.
static func rect(ci: RID, r: Rect2, color: Color, ancho := 2.0, semilla := 0, temblor := 1.2) -> void:
	var esquinas := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		linea(ci, esquinas[i], esquinas[(i + 1) % 4], color, ancho, semilla + i * 31, temblor)


## Círculo a mano alzada: no cierra perfecto y se encima un poco al final.
static func circulo(ci: RID, centro: Vector2, radio: float, color: Color, ancho := 2.0, semilla := 0, temblor := 1.0) -> void:
	var rng := _rng(semilla)
	var inicio := rng.randf() * TAU
	var vuelta := TAU + rng.randf_range(0.15, 0.45)
	var n := maxi(14, int(radio * 0.9))
	var puntos := PackedVector2Array()
	for i in n + 1:
		var angulo := inicio + vuelta * i / n
		puntos.append(centro + Vector2(cos(angulo), sin(angulo)) * (radio + rng.randf_range(-temblor, temblor)))
	RenderingServer.canvas_item_add_polyline(ci, puntos, PackedColorArray([color]), ancho, true)


## Contorno cerrado de cualquier polígono.
static func contorno(ci: RID, poligono: PackedVector2Array, color: Color, ancho := 2.0, semilla := 0, temblor := 1.2) -> void:
	for i in poligono.size():
		linea(ci, poligono[i], poligono[(i + 1) % poligono.size()], color, ancho, semilla + i * 17, temblor)


## Relleno de crayón: una base tenue y encima un rayado diagonal irregular, recortado al polígono.
static func rellenar(ci: RID, poligono: PackedVector2Array, color: Color, semilla := 0, separacion := 4.0, ancho := 2.2) -> void:
	if poligono.size() < 3:
		return
	RenderingServer.canvas_item_add_polygon(ci, poligono, PackedColorArray([Color(color, color.a * 0.35)]))
	var rng := _rng(semilla)
	var caja := _caja(poligono)
	var angulo := deg_to_rad(-55.0 + rng.randf_range(-6.0, 6.0))
	var dir := Vector2(cos(angulo), sin(angulo))
	var normal := Vector2(-dir.y, dir.x)
	var centro := caja.get_center()
	var alcance := caja.size.length() / 2.0 + 4.0
	var desplazamiento := -alcance
	while desplazamiento <= alcance:
		var base := centro + normal * desplazamiento
		var trazo := PackedVector2Array([
			base - dir * alcance,
			base + normal * rng.randf_range(-1.5, 1.5),
			base + dir * alcance,
		])
		var tono := Color(color, color.a * rng.randf_range(0.55, 0.9))
		for parte: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(trazo, poligono):
			RenderingServer.canvas_item_add_polyline(ci, parte, PackedColorArray([tono]), ancho * rng.randf_range(0.8, 1.3), true)
		desplazamiento += separacion * rng.randf_range(0.7, 1.3)


static func rellenar_rect(ci: RID, r: Rect2, color: Color, semilla := 0, separacion := 4.0) -> void:
	rellenar(ci, poligono_rect(r), color, semilla, separacion)


static func rellenar_circulo(ci: RID, centro: Vector2, radio: float, color: Color, semilla := 0, separacion := 3.0) -> void:
	rellenar(ci, poligono_circulo(centro, radio), color, semilla, separacion, 1.8)


## Ficha, punto del dado o botón redondo: relleno de crayón con contorno de lápiz.
static func disco(ci: RID, centro: Vector2, radio: float, color: Color, semilla := 0, borde := LAPIZ) -> void:
	rellenar_circulo(ci, centro, radio, color, semilla, maxf(2.0, radio / 6.0))
	circulo(ci, centro, radio, borde, maxf(1.5, radio / 9.0), semilla + 3, maxf(0.6, radio / 22.0))


static func poligono_rect(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


static func poligono_circulo(centro: Vector2, radio: float, lados := 24) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in lados:
		puntos.append(centro + Vector2.from_angle(TAU * i / lados) * radio)
	return puntos


static func poligono_estrella(centro: Vector2, radio_externo: float, radio_interno: float, puntas := 5) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in puntas * 2:
		var radio := radio_externo if i % 2 == 0 else radio_interno
		puntos.append(centro + Vector2.from_angle(-PI / 2.0 + i * PI / puntas) * radio)
	return puntos


## Semilla estable a partir de un número o de una posición.
static func semilla_de(valor: Variant) -> int:
	return hash(valor)


static func _rng(semilla: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	return rng


static func _caja(poligono: PackedVector2Array) -> Rect2:
	var caja := Rect2(poligono[0], Vector2.ZERO)
	for punto in poligono:
		caja = caja.expand(punto)
	return caja
