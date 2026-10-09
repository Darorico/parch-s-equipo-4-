class_name AvatarIcono
extends Control
## Avatar de un jugador: círculo de su color con una figura blanca elegida al registrarse.
## Con forma = -1 se dibuja solo el punto de color (para el selector de color).

const FORMAS := ["Estrella", "Rombo", "Anillo", "Triángulo"]

var color := Color.GRAY:
	set(valor):
		color = valor
		queue_redraw()
var forma := 0:
	set(valor):
		forma = valor
		queue_redraw()


func _init(p_color := Color.GRAY, p_forma := 0, tamano := 36.0) -> void:
	color = p_color
	forma = p_forma
	custom_minimum_size = Vector2(tamano, tamano)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var centro := size / 2.0
	var radio := minf(size.x, size.y) / 2.0
	draw_circle(centro, radio, color)
	var blanco := Color.WHITE
	match forma:
		0:
			draw_colored_polygon(_estrella(centro, radio * 0.58, radio * 0.25, 5), blanco)
		1:
			draw_colored_polygon(PackedVector2Array([
				centro + Vector2(0, -radio * 0.5), centro + Vector2(radio * 0.4, 0),
				centro + Vector2(0, radio * 0.5), centro + Vector2(-radio * 0.4, 0),
			]), blanco)
		2:
			draw_arc(centro, radio * 0.32, 0.0, TAU, 32, blanco, radio * 0.16, true)
		3:
			draw_colored_polygon(PackedVector2Array([
				centro + Vector2(0, -radio * 0.45), centro + Vector2(radio * 0.45, radio * 0.35),
				centro + Vector2(-radio * 0.45, radio * 0.35),
			]), blanco)


static func _estrella(centro: Vector2, radio_externo: float, radio_interno: float, puntas: int) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in puntas * 2:
		var angulo := -PI / 2.0 + i * PI / puntas
		var radio := radio_externo if i % 2 == 0 else radio_interno
		puntos.append(centro + Vector2(cos(angulo), sin(angulo)) * radio)
	return puntos
