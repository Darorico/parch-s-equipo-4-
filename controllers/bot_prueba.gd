class_name BotPrueba
extends Node
## Jugador automático SOLO para pruebas (`-- --auto`). Usa los mismos controladores que la Vista,
## así que recorre exactamente el mismo flujo del caso de uso. Sale después de `max_turnos` cambios de turno.
## Con `--capturas=carpeta` guarda una captura de pantalla en cada paso (para revisar la interfaz).

var _turno: ControladorTurno
var _lobby: ControladorLobby
var _cambios_de_turno := 0
var _max_turnos := 10
var _carpeta_capturas := ""
var _capturas := 0


func configurar(partida: Partida, turno: ControladorTurno, lobby: ControladorLobby, max_turnos: int, carpeta_capturas := "") -> void:
	_turno = turno
	_lobby = lobby
	_max_turnos = max_turnos
	_carpeta_capturas = carpeta_capturas
	partida.jugador_registrado.connect(_on_jugador_registrado)
	partida.turno_cambiado.connect(_on_turno_cambiado)
	partida.opciones_turno.connect(_on_opciones_turno)
	partida.error_recibido.connect(_on_error)
	partida.partida_terminada.connect(_on_partida_terminada)


func _on_jugador_registrado(jugador_id: int) -> void:
	if jugador_id == Red.mi_id():
		await capturar("sala_espera")
		_lobby.confirmar_estado(true)


func _on_turno_cambiado(jugador_id: int) -> void:
	_cambios_de_turno += 1
	if _cambios_de_turno > _max_turnos:
		print("[bot %d] Fin de la prueba tras %d turnos" % [Red.mi_id(), _max_turnos])
		get_tree().quit()
		return
	if jugador_id == Red.mi_id():
		await capturar("turno")
		_turno.procesar_lanzamiento_dado()


func _on_opciones_turno(jugador_id: int, movibles: Array, puede_liberar: bool) -> void:
	if jugador_id != Red.mi_id():
		return
	await capturar("eligiendo_ficha")
	if puede_liberar:
		_turno.liberar_ficha()
	else:
		_turno.mover_ficha(movibles[0])


func _on_error(texto: String) -> void:
	print("[bot %d] ERROR: %s" % [Red.mi_id(), texto])


func _on_partida_terminada(ganador_id: int, motivo: String) -> void:
	print("[bot %d] Partida terminada, ganador %d: %s" % [Red.mi_id(), ganador_id, motivo])
	get_tree().quit()


## Espera un momento (para que se vea la pantalla) y, si se pidió, guarda una captura.
func capturar(nombre: String) -> void:
	if _carpeta_capturas == "":
		await get_tree().create_timer(0.2).timeout
		return
	await get_tree().create_timer(1.2).timeout
	var imagen := get_viewport().get_texture().get_image()
	imagen.save_png("%s/%d_%02d_%s.png" % [_carpeta_capturas, Red.mi_id(), _capturas, nombre])
	_capturas += 1
