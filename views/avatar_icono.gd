@tool
class_name AvatarIcono
extends Control
## Avatar de un jugador dibujado a crayón: un círculo de lápiz de su color con la figura elegida
## (estrella, rombo, anillo o triángulo) coloreada dentro. Con forma = -1 se dibuja solo una bolita
## de color (para el selector de color).

const FORMAS := ["Estrella", "Rombo", "Anillo", "Triángulo"]

## Color del jugador.
@export var color := Color.GRAY:
	set(valor):
		color = valor
		queue_redraw()
## Figura del avatar: 0 estrella, 1 rombo, 2 anillo, 3 triángulo; -1 solo bolita de color.
@export_range(-1, 3) var forma := 0:
	set(valor):
		forma = valor
		queue_redraw()


func _init(p_color := Color.GRAY, p_forma := 0, tamano := 36.0) -> void:
	color = p_color
	forma = p_forma
	custom_minimum_size = Vector2(tamano, tamano)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(Garabato.GRUPO_VIVO)


func _draw() -> void:
	var ci := get_canvas_item()
	var centro := size / 2.0
	var radio := minf(size.x, size.y) / 2.0 - 2.0
	var semilla := Garabato.semilla_de(forma) + Garabato.cuadro % 3
	if forma < 0:
		Garabato.disco(ci, centro, radio, color, semilla)
		return
	Garabato.circulo(ci, centro, radio, color, maxf(2.0, radio / 8.0), semilla, 0.8)
	var figura: PackedVector2Array
	match forma:
		0:
			figura = Garabato.poligono_estrella(centro, radio * 0.68, radio * 0.3)
		1:
			figura = PackedVector2Array([
				centro + Vector2(0, -radio * 0.62), centro + Vector2(radio * 0.42, 0),
				centro + Vector2(0, radio * 0.62), centro + Vector2(-radio * 0.42, 0),
			])
		2:
			Garabato.circulo(ci, centro, radio * 0.45, color, maxf(2.0, radio / 7.0), semilla + 5, 0.5)
			Garabato.rellenar_circulo(ci, centro, radio * 0.18, color, semilla + 6)
			return
		_:
			figura = PackedVector2Array([
				centro + Vector2(0, -radio * 0.55), centro + Vector2(radio * 0.55, radio * 0.42),
				centro + Vector2(-radio * 0.55, radio * 0.42),
			])
	Garabato.rellenar(ci, figura, color, semilla + 1, 2.5, 1.8)
	Garabato.contorno(ci, figura, color.darkened(0.25), 1.6, semilla + 2, 0.5)
