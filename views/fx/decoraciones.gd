@tool
class_name Decoraciones
extends Control
## Garabatos de los márgenes de la hoja, como en las referencias: estrellitas, espirales, rayones de
## crayón y un crayón café. Van detrás de las pantallas y no reciben clics. Tiemblan en stop-motion.

const MARRON := Color("#7a4a2a")


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(Garabato.GRUPO_VIVO)


func _draw() -> void:
	var ci := get_canvas_item()
	var s := Garabato.cuadro % 3  # Solo 3 variantes: tiembla sin parecer ruido.
	var w := size.x
	var h := size.y
	# Las decoraciones quedan pegadas a las orillas, fuera de los márgenes de las pantallas.
	# Esquina superior izquierda: rayones azul y café.
	_rayones(ci, Vector2(-4, -12), Estilo.color_de("azul"), 30 + s)
	_estrella(ci, Vector2(16, 120), 8, 1 + s)
	# Esquina superior derecha: rayón naranja.
	_rayones(ci, Vector2(w - 40, -14), Color("#f08a24"), 50 + s)
	_estrella(ci, Vector2(w - 16, 120), 7, 2 + s)
	# Esquina inferior izquierda: crayón y estrellas.
	_crayon(ci, Vector2(8, h - 8), Vector2(34, h - 70), 3 + s)
	_estrella(ci, Vector2(18, h - 100), 7, 4 + s)
	# Esquina inferior derecha: espirales de colores y puntitos.
	_espiral(ci, Vector2(w - 20, h - 26), 12, Estilo.color_de("verde"), 6 + s)
	_espiral(ci, Vector2(w - 20, h - 76), 8, Estilo.color_de("rojo"), 7 + s)
	for i in 3:
		Garabato.rellenar_circulo(ci, Vector2(w - 12, h - 112 - i * 18), 3.0, Estilo.color_de(["amarillo", "azul", "rojo"][i]), 60 + i)


func _estrella(ci: RID, centro: Vector2, radio: float, semilla: int) -> void:
	Garabato.contorno(ci, Garabato.poligono_estrella(centro, radio, radio * 0.45), Garabato.LAPIZ, 1.6, semilla, 0.6)


func _espiral(ci: RID, centro: Vector2, radio: float, color: Color, semilla: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var puntos := PackedVector2Array()
	for i in 60:
		var t := i / 60.0
		puntos.append(centro + Vector2.from_angle(t * TAU * 2.6) * radio * t + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6)))
	RenderingServer.canvas_item_add_polyline(ci, puntos, PackedColorArray([color]), 2.0, true)


func _rayones(ci: RID, origen: Vector2, color: Color, semilla: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	for i in 7:
		var a := origen + Vector2(i * 7 + rng.randf_range(-2, 2), 0)
		Garabato.linea(ci, a, a + Vector2(-26, 34) + Vector2(rng.randf_range(-4, 4), 0), Color(color, 0.7), 3.0, semilla + i, 1.5)


func _crayon(ci: RID, base: Vector2, punta: Vector2, semilla: int) -> void:
	var dir := (punta - base).normalized()
	var normal := Vector2(-dir.y, dir.x) * 9.0
	var cuerpo_fin := punta - dir * 16.0
	var cuerpo := PackedVector2Array([base + normal, cuerpo_fin + normal, cuerpo_fin - normal, base - normal])
	Garabato.rellenar(ci, cuerpo, MARRON, semilla, 3.0)
	Garabato.contorno(ci, cuerpo, Garabato.LAPIZ, 1.8, semilla + 1, 0.6)
	var cono := PackedVector2Array([cuerpo_fin + normal * 0.8, punta, cuerpo_fin - normal * 0.8])
	Garabato.rellenar(ci, cono, MARRON.darkened(0.2), semilla + 2, 2.5)
	Garabato.contorno(ci, cono, Garabato.LAPIZ, 1.6, semilla + 3, 0.5)
	for k in [0.3, 0.6]:
		var p := base.lerp(cuerpo_fin, k)
		Garabato.linea(ci, p + normal, p - normal, Garabato.LAPIZ, 1.4, semilla + 4, 0.4)
