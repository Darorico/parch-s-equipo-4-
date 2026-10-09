class_name PanelJugadores
extends PanelContainer
## Panel «Jugadores» del storyboard: avatar, nombre, color y fichas en meta de cada jugador.
## Resalta claramente al jugador al que le corresponde el turno.
## Diseño: views/escenas/panel_jugadores.tscn (cada fila es una FilaJugador).

@onready var _filas: VBoxContainer = %Filas
@onready var _texto_turno: Label = %TextoTurno

var _jugadores: Array = []
var _mi_id := 0
var _turno_id := 0


func mostrar(jugadores: Array, mi_id: int) -> void:
	_jugadores = jugadores
	_mi_id = mi_id
	_redibujar()


func marcar_turno(jugador_id: int) -> void:
	_turno_id = jugador_id
	_redibujar()


func _redibujar() -> void:
	Estilo.vaciar(_filas)
	_texto_turno.text = "Esperando el primer turno..."
	for datos: Dictionary in _jugadores:
		var es_turno: bool = datos.id == _turno_id
		var fila := FilaJugador.crear()
		_filas.add_child(fila)
		var detalle := "%s · %d fichas en meta" % [Estilo.NOMBRES[datos.color], datos.fichas_en_meta]
		fila.mostrar(datos, datos.id == _mi_id, detalle, "Turno" if es_turno else "", Estilo.PRIMARIO,
				Estilo.TEXTO_BOTON, es_turno)
		if es_turno:
			_texto_turno.text = "Turno de %s · %d fichas en meta" % [datos.nombre, datos.fichas_en_meta]
