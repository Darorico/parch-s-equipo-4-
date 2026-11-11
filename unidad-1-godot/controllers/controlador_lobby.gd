class_name ControladorLobby
extends RefCounted
## Controlador de las pantallas previas a la partida: CU01 Registrar Jugador y CU02 Confirmar Estado.

var _partida: Partida
var _registro_pendiente: Array = []


func _init(partida: Partida) -> void:
	_partida = partida
	Red.conectado.connect(_on_conectado)


## Se conecta al servidor y, en cuanto hay conexión, envía el registro.
func unirse_a_partida(url: String, nombre: String, color: String, avatar: int) -> void:
	_registro_pendiente = [nombre, color, avatar]
	if Red.unirse(url) != OK:
		_registro_pendiente = []
		_partida.notificar_error("Dirección de servidor inválida: %s" % url)


## Este equipo hace de servidor y además juega (solo en escritorio).
func hospedar_partida(nombre: String, color: String, avatar: int) -> void:
	if Red.hospedar() != OK:
		_partida.notificar_error("No se pudo abrir el puerto %d. ¿Ya hay un servidor corriendo?" % Red.PUERTO)
		return
	registrar_jugador(nombre, color, avatar)


func registrar_jugador(nombre: String, color: String, avatar: int) -> void:
	Red.solicitar(&"registrar", [nombre, color, avatar])


func confirmar_estado(listo: bool) -> void:
	Red.solicitar(&"listo", [listo])


func salir() -> void:
	Red.cerrar()
	_partida.reiniciar()


func _on_conectado() -> void:
	if not _registro_pendiente.is_empty():
		registrar_jugador.callv(_registro_pendiente)
		_registro_pendiente = []
