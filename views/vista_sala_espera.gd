class_name VistaSalaEspera
extends Control
## Pantalla 02 del storyboard: Sala de espera / Arranque (CU02 Confirmar Estado y CU03 Iniciar Partida).
## OBSERVA al Modelo (jugadores_actualizados) para pintar la lista; el botón «Listo» va al ControladorLobby.
## Diseño: views/escenas/vista_sala_espera.tscn (cada jugador es una FilaJugador).

@onready var _lista: VBoxContainer = %Lista
@onready var _resumen: Label = %Resumen
@onready var _conectados: Label = %Conectados
@onready var _boton_listo: Button = %BotonListo
@onready var _estado: Label = %Estado

var _lobby: ControladorLobby
var _mi_id := 0
var _estoy_listo := false


func _ready() -> void:
	_boton_listo.pressed.connect(_on_listo)


## Se llama después de agregar la vista al árbol.
func configurar(partida: Partida, lobby: ControladorLobby, mi_id: int) -> void:
	_lobby = lobby
	_mi_id = mi_id
	partida.jugadores_actualizados.connect(_on_jugadores_actualizados)
	partida.error_recibido.connect(_on_error)


func _on_jugadores_actualizados(jugadores: Array) -> void:
	Estilo.vaciar(_lista)
	var listos := 0
	for datos: Dictionary in jugadores:
		if datos.listo:
			listos += 1
		if datos.id == _mi_id:
			_estoy_listo = datos.listo
		var fila := FilaJugador.crear()
		_lista.add_child(fila)
		var detalle := "%s · %s" % [Estilo.NOMBRES[datos.color], "listo" if datos.listo else "esperando"]
		if datos.listo:
			fila.mostrar(datos, datos.id == _mi_id, detalle, "Listo", Estilo.EXITO, Estilo.EXITO_TEXTO)
		else:
			fila.mostrar(datos, datos.id == _mi_id, detalle, "Esperando", Estilo.PRIMARIO_SUAVE, Estilo.TEXTO)
	_resumen.text = "%d/%d listos · se necesitan al menos %d jugadores y que todos confirmen." % [listos, jugadores.size(), Partida.MIN_JUGADORES]
	_conectados.text = "%d de %d jugadores conectados" % [jugadores.size(), Partida.MAX_JUGADORES]
	_boton_listo.text = "CANCELAR «LISTO»" if _estoy_listo else "LISTO"
	_boton_listo.theme_type_variation = &"" if _estoy_listo else &"BotonPrimario"
	_boton_listo.disabled = false


func _on_listo() -> void:
	_boton_listo.disabled = true
	_estado.text = ""
	_lobby.confirmar_estado(not _estoy_listo)


func _on_error(texto: String) -> void:
	_boton_listo.disabled = false
	_estado.text = texto
