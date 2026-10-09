@tool
class_name DadoVista
extends Control
## Dado dibujado a lápiz. Al recibir un valor «rueda» unos cuadros a saltos (stop-motion),
## ladeándose en cada cuadro, y se queda en ese valor.
## Es también el botón para lanzar: cuando está `activo` (tu turno) se resalta con crayón amarillo
## y al hacerle clic emite `presionado`.

signal presionado

## Cuántos cuadros rueda el dado antes de mostrar el resultado.
const CUADROS_ANIMACION := 4
const PUNTOS := {
	1: [Vector2(0, 0)],
	2: [Vector2(-1, -1), Vector2(1, 1)],
	3: [Vector2(-1, -1), Vector2(0, 0), Vector2(1, 1)],
	4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
	5: [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)],
	6: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)],
}

## Cara que se muestra (0 = «?»). Se puede cambiar en el Inspector para ver cómo queda.
@export_range(0, 6) var valor := 0:
	set(nuevo):
		valor = nuevo
		queue_redraw()
## Se puede hacer clic para lanzar (lo activa el panel cuando es tu turno).
@export var activo := false:
	set(nuevo):
		activo = nuevo
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if activo else Control.CURSOR_ARROW
		queue_redraw()
var _inclinacion := 0.0
var _animacion := 0


func _init() -> void:
	custom_minimum_size = Vector2(80, 80)
	add_to_group(Garabato.GRUPO_VIVO)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Haz clic para lanzar el dado"


## Segundos que dura animar(); quien la llama espera esto antes de mostrar el resultado.
static func duracion_animacion() -> float:
	return (CUADROS_ANIMACION + 1) / Animaciones.CUADROS_POR_SEGUNDO


func _gui_input(event: InputEvent) -> void:
	var clic := event as InputEventMouseButton
	if activo and clic and clic.pressed and clic.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		activo = false
		presionado.emit()


func animar(valor_final: int) -> void:
	_animacion += 1
	var esta_animacion := _animacion
	Sonidos.dado()
	for i in CUADROS_ANIMACION:
		if esta_animacion != _animacion or not is_inside_tree():
			return
		valor = randi_range(1, 6)
		_inclinacion = randf_range(-0.35, 0.35)
		queue_redraw()
		await Animaciones.esperar_cuadros(1)
	if esta_animacion == _animacion:
		valor = valor_final
		_inclinacion = 0.0
		queue_redraw()


func _draw() -> void:
	var ci := get_canvas_item()
	var lado := minf(size.x, size.y) - 10.0
	var centro := size / 2.0
	var semilla := 900 + Garabato.cuadro % 3
	if activo:
		# Resaltador amarillo detrás del dado: «¡haz clic aquí!».
		Garabato.rellenar_circulo(ci, centro, lado * 0.72, Color(Estilo.RESALTADOR, 0.85), semilla + 40, 3.0)
	draw_set_transform(centro, _inclinacion, Vector2.ONE)
	var cuadrado := Rect2(-Vector2(lado, lado) / 2.0, Vector2(lado, lado))
	RenderingServer.canvas_item_add_rect(ci, cuadrado, Estilo.PAPEL)
	Garabato.rect(ci, cuadrado, Garabato.LAPIZ, 2.4, semilla, 1.2)
	if valor == 0:
		var tamano := int(lado * 0.55)
		draw_string(Estilo.negrita(), Vector2(cuadrado.position.x, tamano * 0.35), "?",
				HORIZONTAL_ALIGNMENT_CENTER, lado, tamano, Estilo.TEXTO_SUAVE)
	else:
		for punto: Vector2 in PUNTOS[valor]:
			Garabato.disco(ci, punto * lado * 0.26, lado * 0.085, Garabato.LAPIZ, semilla + int(punto.x * 7 + punto.y * 13))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
