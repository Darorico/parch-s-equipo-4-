class_name DadoVista
extends Control
## Cara del dado. Al recibir un valor hace una pequeña animación y se queda en ese valor.

const DURACION_ANIMACION := 0.55
const PUNTOS := {
	1: [Vector2(0, 0)],
	2: [Vector2(-1, -1), Vector2(1, 1)],
	3: [Vector2(-1, -1), Vector2(0, 0), Vector2(1, 1)],
	4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
	5: [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)],
	6: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)],
}

var valor := 0
var _animacion := 0


func _init() -> void:
	custom_minimum_size = Vector2(76, 76)


func animar(valor_final: int) -> void:
	_animacion += 1
	var esta_animacion := _animacion
	var pasos := 9
	for i in pasos:
		if esta_animacion != _animacion or not is_inside_tree():
			return
		valor = randi_range(1, 6)
		queue_redraw()
		await get_tree().create_timer(DURACION_ANIMACION / pasos).timeout
	if esta_animacion == _animacion:
		valor = valor_final
		queue_redraw()


func _draw() -> void:
	var lado := minf(size.x, size.y) - 4.0
	var rect := Rect2((size - Vector2(lado, lado)) / 2.0, Vector2(lado, lado))
	draw_style_box(Estilo.caja(Color.WHITE, 14, Estilo.BORDE), rect)
	var centro := rect.get_center()
	if valor == 0:
		var fuente := Estilo.negrita()
		var tamano := int(lado * 0.45)
		draw_string(fuente, Vector2(rect.position.x, centro.y + tamano * 0.35), "?",
				HORIZONTAL_ALIGNMENT_CENTER, lado, tamano, Estilo.TEXTO_SUAVE)
		return
	for punto: Vector2 in PUNTOS[valor]:
		draw_circle(centro + punto * lado * 0.26, lado * 0.085, Estilo.TEXTO)
