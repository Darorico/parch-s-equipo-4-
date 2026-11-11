extends Node
## CONTROLADOR DE RED (autoload «Red»). Implementa CU09 Sincronizar Tablero.
##
## Usa un servidor autoritativo sobre WebSocket (funciona desde el navegador):
##   - Clientes → servidor: las acciones del usuario (registrar, listo, lanzar_dado, liberar_ficha,
##     mover_ficha). El servidor valida quién las manda y se las pasa a su Partida.
##   - Servidor → clientes: cada señal de la Partida autoritativa se reenvía a todos los clientes, que la
##     aplican en su réplica de la Partida; la réplica vuelve a emitir la señal y su Vista la observa.

signal conectado
signal desconectado(motivo: String)

const PUERTO := 9080

var partida: Partida
var es_servidor := false
var _peer: WebSocketMultiplayerPeer


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_conectado)
	multiplayer.connection_failed.connect(_on_conexion_fallida)
	multiplayer.server_disconnected.connect(_on_servidor_desconectado)
	multiplayer.peer_connected.connect(_on_peer_conectado)
	multiplayer.peer_disconnected.connect(_on_peer_desconectado)


func configurar(p_partida: Partida) -> void:
	partida = p_partida


## Convierte este equipo en el servidor de la partida.
func hospedar(puerto: int = PUERTO) -> Error:
	cerrar()
	_peer = WebSocketMultiplayerPeer.new()
	var error := _peer.create_server(puerto)
	if error != OK:
		_peer = null
		return error
	multiplayer.multiplayer_peer = _peer
	es_servidor = true
	partida.evento_emitido.connect(_difundir)
	print("[servidor] Escuchando en ws://0.0.0.0:%d" % puerto)
	return OK


## Se conecta a un servidor, por ejemplo ws://192.168.1.10:9080 o ws://100.x.y.z:9080 (Tailscale).
func unirse(url: String) -> Error:
	cerrar()
	_peer = WebSocketMultiplayerPeer.new()
	var error := _peer.create_client(url)
	if error != OK:
		_peer = null
		return error
	multiplayer.multiplayer_peer = _peer
	return OK


func cerrar() -> void:
	if partida and partida.evento_emitido.is_connected(_difundir):
		partida.evento_emitido.disconnect(_difundir)
	if _peer:
		_peer.close()
	_peer = null
	es_servidor = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func mi_id() -> int:
	return multiplayer.get_unique_id()


func esta_conectado() -> bool:
	return _peer != null and _peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Envía una acción del usuario al Modelo autoritativo (local si este equipo es el servidor).
func solicitar(accion: StringName, args: Array = []) -> void:
	if es_servidor:
		_ejecutar(mi_id(), accion, args)
	elif esta_conectado():
		_srv_accion.rpc_id(1, accion, args)
	else:
		partida.notificar_error("Sin conexión con el servidor.")


# ---------------------------------------------------------------------------
# RPC
# ---------------------------------------------------------------------------

@rpc("any_peer", "call_remote", "reliable")
func _srv_accion(accion: StringName, args: Array) -> void:
	if es_servidor:
		_ejecutar(multiplayer.get_remote_sender_id(), accion, args)


@rpc("authority", "call_remote", "reliable")
func _cli_evento(nombre: StringName, args: Array) -> void:
	print("[cliente %d] %s %s" % [mi_id(), nombre, args])
	partida.aplicar_evento(nombre, args)


@rpc("authority", "call_remote", "reliable")
func _cli_error(texto: String) -> void:
	partida.notificar_error(texto)


## El servidor traduce la acción a una llamada al Modelo. El remitente lo da la red, no el cliente.
func _ejecutar(jugador_id: int, accion: StringName, args: Array) -> void:
	var error := ""
	match String(accion):
		"registrar":
			if args.size() == 3:
				error = partida.registrar_jugador(jugador_id, str(args[0]), str(args[1]), _entero(args[2]))
			else:
				error = "Datos de registro incompletos."
		"listo":
			error = partida.confirmar_estado(jugador_id, args.size() == 1 and args[0] == true)
		"lanzar_dado":
			error = partida.lanzar_dado(jugador_id)
		"liberar_ficha":
			error = partida.liberar_ficha(jugador_id)
		"mover_ficha":
			error = partida.mover_ficha(jugador_id, _entero(args[0]) if args.size() == 1 else 0)
		_:
			error = "Acción desconocida."
	if error == "":
		return
	if jugador_id == mi_id():
		partida.notificar_error(error)
	else:
		_cli_error.rpc_id(jugador_id, error)


func _difundir(nombre: StringName, args: Array) -> void:
	print("[servidor] %s %s" % [nombre, args])
	for id in multiplayer.get_peers():
		var conexion := _peer.get_peer(id)
		# Se omiten las conexiones que se están cerrando (un jugador que acaba de salir).
		if conexion and conexion.get_ready_state() == WebSocketPeer.STATE_OPEN:
			_cli_evento.rpc_id(id, nombre, args)


# ---------------------------------------------------------------------------
# Eventos de conexión
# ---------------------------------------------------------------------------

func _on_conectado() -> void:
	print("[cliente %d] Conectado al servidor" % mi_id())
	conectado.emit()


func _on_conexion_fallida() -> void:
	cerrar()
	partida.reiniciar()
	desconectado.emit("No se pudo conectar con el servidor. Revisa la dirección y que el servidor esté encendido.")


func _on_servidor_desconectado() -> void:
	cerrar()
	partida.reiniciar()
	desconectado.emit("Se perdió la conexión con el servidor.")


func _on_peer_conectado(id: int) -> void:
	if es_servidor:
		print("[servidor] Se conectó el equipo %d" % id)


func _on_peer_desconectado(id: int) -> void:
	if es_servidor:
		print("[servidor] Se desconectó el equipo %d" % id)
		partida.quitar_jugador(id)


static func _entero(valor: Variant) -> int:
	return int(valor) if typeof(valor) in [TYPE_INT, TYPE_FLOAT] else -1
