class_name Ficha
extends RefCounted
## Ficha de un jugador. Su posición la decide el subsistema de reglas (a través de la fachada);
## el Modelo solo guarda una copia para notificarla a las vistas.

enum Estado { CASA, EN_JUEGO, META }

const EN_CASA := -1

var id: int
var color: String
## Índice de la casilla en el recorrido (0..67) o EN_CASA.
var casilla: int = EN_CASA

var estado: Estado:
	get:
		return Estado.CASA if casilla == EN_CASA else Estado.EN_JUEGO


func _init(p_id: int, p_color: String) -> void:
	id = p_id
	color = p_color
