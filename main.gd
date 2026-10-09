extends Control
## Raíz de composición de la aplicación: crea el Modelo (Partida con su FachadaReglas y el Mock),
## los Controladores y las Vistas, y cambia de pantalla observando al Modelo. También pone la hoja
## de cuaderno (papel arrugado y garabatos de los márgenes) detrás de todas las pantallas.
##
## Argumentos de línea de comandos (después de `--`):
##   --servidor            Servidor dedicado sin interfaz (se activa solo con --headless).
##   --puerto=9080         Puerto del servidor.
##   --dados=5,3,6         Valores forzados del dado en el Mock (para grabar una demo reproducible).
##   --cliente=Nombre      Nombre precargado en el registro.
##   --url=ws://...:9080   Servidor precargado en el registro.
##   --color=rojo          Color precargado.
##   --auto                Jugador automático para pruebas (se registra y juega solo).
##   --turnos=10           Con --auto: cambios de turno antes de salir.
##   --capturas=carpeta    Con --auto: guarda capturas de pantalla de cada paso.

var partida: Partida
var controlador_turno: ControladorTurno
var controlador_lobby: ControladorLobby
var _pantalla: Control
var _args := {}


func _ready() -> void:
	_args = _leer_argumentos()
	partida = Partida.new()
	partida.name = "Partida"
	add_child(partida)
	partida.fachada = FachadaReglas.new(ReglasMock.new(_secuencia_dados()))
	Red.configurar(partida)

	if _args.has("servidor") or (DisplayServer.get_name() == "headless" and not _args.has("cliente")):
		_iniciar_servidor_dedicado()
		return

	controlador_turno = ControladorTurno.new()
	controlador_lobby = ControladorLobby.new(partida)
	theme = Estilo.crear_tema()
	RenderingServer.set_default_clear_color(Estilo.PAPEL)
	_crear_hoja_de_cuaderno()

	partida.jugador_registrado.connect(_on_jugador_registrado)
	partida.partida_iniciada.connect(_on_partida_iniciada)
	Red.desconectado.connect(_on_desconectado)
	_mostrar_registro()

	if _args.has("auto"):
		var bot := BotPrueba.new()
		add_child(bot)
		bot.configurar(partida, controlador_turno, controlador_lobby, int(_args.get("turnos", "10")), _args.get("capturas", ""))
		await bot.capturar("registro")
		controlador_lobby.unirse_a_partida(_url_por_defecto(), _args.get("cliente", "Bot"), _args.get("color", "verde"), 0)


func _iniciar_servidor_dedicado() -> void:
	var puerto := int(_args.get("puerto", str(Red.PUERTO)))
	if Red.hospedar(puerto) != OK:
		push_error("No se pudo abrir el puerto %d" % puerto)
		get_tree().quit(1)


# --- Navegación (observa al Modelo) ---

func _on_jugador_registrado(jugador_id: int) -> void:
	if jugador_id == Red.mi_id() and _pantalla is VistaRegistro:
		var sala := VistaSalaEspera.new()
		sala.configurar(partida, controlador_lobby, Red.mi_id())
		_cambiar_pantalla(sala)


func _on_partida_iniciada(jugadores: Array, _orden: Array) -> void:
	if not jugadores.any(func(datos: Dictionary) -> bool: return datos.id == Red.mi_id()):
		return
	var vista := VistaTablero.new()
	vista.configurar(partida, controlador_turno, Red.mi_id(), jugadores)
	vista.volver_al_inicio.connect(_on_volver_al_inicio)
	_cambiar_pantalla(vista)


func _on_desconectado(motivo: String) -> void:
	_mostrar_registro(motivo)


func _on_volver_al_inicio() -> void:
	controlador_lobby.salir()
	_mostrar_registro()


func _mostrar_registro(aviso := "") -> void:
	var vista := VistaRegistro.new()
	var datos := {"nombre": _args.get("cliente", ""), "url": _url_por_defecto(), "color": _args.get("color", "")}
	if aviso != "":
		datos.aviso = aviso
	vista.configurar(partida, controlador_lobby, datos)
	_cambiar_pantalla(vista)


## La pantalla nueva se agrega de inmediato (ya conectada al Modelo, para no perder eventos) y una
## hoja de papel la destapa a saltos (GestorAnimaciones.transicion_pantalla).
func _cambiar_pantalla(nueva: Control) -> void:
	if _pantalla:
		_pantalla.queue_free()
	_pantalla = nueva
	add_child(nueva)
	Animaciones.transicion_pantalla()


func _crear_hoja_de_cuaderno() -> void:
	var papel := FondoPapel.new()
	papel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(papel)
	add_child(Decoraciones.new())


# --- Utilidades ---

func _url_por_defecto() -> String:
	if _args.has("url"):
		return _args.url
	if OS.has_feature("web"):
		# En el navegador, el servidor de juego suele estar en el mismo equipo que sirve la página.
		var protocolo = JavaScriptBridge.eval("window.location.protocol")
		if protocolo == "https:":
			# Detrás de HTTPS (tailscale serve) el WebSocket va por el mismo dominio, en la ruta /ws.
			return "wss://%s/ws" % JavaScriptBridge.eval("window.location.host")
		var host = JavaScriptBridge.eval("window.location.hostname")
		if host is String and host != "":
			return "ws://%s:%d" % [host, Red.PUERTO]
	return "ws://127.0.0.1:%d" % Red.PUERTO


func _secuencia_dados() -> Array[int]:
	var secuencia: Array[int] = []
	for valor in String(_args.get("dados", "")).split(",", false):
		secuencia.append(int(valor))
	return secuencia


static func _leer_argumentos() -> Dictionary:
	var args := {}
	for argumento in OS.get_cmdline_user_args():
		if not argumento.begins_with("--"):
			continue
		var partes := argumento.substr(2).split("=", true, 1)
		args[partes[0]] = partes[1] if partes.size() > 1 else ""
	return args
