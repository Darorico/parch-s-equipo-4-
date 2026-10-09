class_name VistaRegistro
extends MarginContainer
## Pantalla 01 del storyboard: Registro / Membresía (CU01 Registrar Jugador).
## Manda la acción al ControladorLobby y observa al Modelo para mostrar los errores.

var _lobby: ControladorLobby
var _nombre := LineEdit.new()
var _servidor := LineEdit.new()
var _grupo_color := ButtonGroup.new()
var _grupo_avatar := ButtonGroup.new()
var _avatares: Array[AvatarIcono] = []
var _boton_unirse := Button.new()
var _boton_hospedar := Button.new()
var _estado := Estilo.parrafo("", 13)


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		add_theme_constant_override("margin_" + lado, 40)
	for lado in ["top", "bottom"]:
		add_theme_constant_override("margin_" + lado, 26)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 22)
	add_child(raiz)
	raiz.add_child(Estilo.encabezado("01", "REGISTRO / MEMBRESÍA", "Cada jugador se registra",
			"Nombre de usuario, color y avatar. La información se sincroniza con los demás jugadores."))

	var centro := HBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 20)
	raiz.add_child(centro)

	var formulario := VBoxContainer.new()
	formulario.custom_minimum_size.x = 460
	formulario.add_theme_constant_override("separation", 8)
	centro.add_child(Estilo.tarjeta("Registro individual", formulario))

	formulario.add_child(Estilo.rotulo("NOMBRE DE USUARIO"))
	_nombre.placeholder_text = "Ej. Nico"
	_nombre.max_length = 16
	formulario.add_child(_nombre)

	formulario.add_child(Estilo.rotulo("COLOR DE FICHA"))
	var fila_colores := HBoxContainer.new()
	fila_colores.add_theme_constant_override("separation", 8)
	for color in Jugador.COLORES:
		var icono := AvatarIcono.new(Estilo.color_de(color), -1, 18)
		fila_colores.add_child(_opcion(icono, Estilo.NOMBRES[color], _grupo_color, color))
	formulario.add_child(fila_colores)

	formulario.add_child(Estilo.rotulo("AVATAR"))
	var fila_avatares := HBoxContainer.new()
	fila_avatares.add_theme_constant_override("separation", 8)
	for i in AvatarIcono.FORMAS.size():
		var icono := AvatarIcono.new(Estilo.color_de(Jugador.COLORES[0]), i, 34)
		_avatares.append(icono)
		fila_avatares.add_child(_opcion(icono, "", _grupo_avatar, i))
	formulario.add_child(fila_avatares)

	formulario.add_child(Estilo.rotulo("SERVIDOR"))
	_servidor.placeholder_text = "ws://IP-del-servidor:%d" % Red.PUERTO
	formulario.add_child(_servidor)

	formulario.add_child(Estilo.aviso("La información se sincroniza con el resto de los jugadores al registrarte."))
	_boton_unirse.text = "Unirse a la partida"
	_boton_unirse.theme_type_variation = &"BotonPrimario"
	_boton_unirse.custom_minimum_size.y = 44
	_boton_unirse.pressed.connect(_on_unirse)
	formulario.add_child(_boton_unirse)
	_boton_hospedar.text = "Hospedar partida en este equipo"
	_boton_hospedar.visible = not OS.has_feature("web")
	_boton_hospedar.pressed.connect(_on_hospedar)
	formulario.add_child(_boton_hospedar)
	formulario.add_child(_estado)

	var ayuda := VBoxContainer.new()
	ayuda.custom_minimum_size.x = 320
	ayuda.add_theme_constant_override("separation", 10)
	ayuda.add_child(Estilo.parrafo("1. Un equipo corre el servidor (botón «Hospedar» o scripts/servidor.ps1)."))
	ayuda.add_child(Estilo.parrafo("2. Los demás escriben ws://<IP del servidor>:%d (IP de la red local o de Tailscale)." % Red.PUERTO))
	ayuda.add_child(Estilo.parrafo("3. Con 2 a 4 jugadores registrados, cuando todos confirman «Listo» la partida inicia sola."))
	ayuda.add_child(Estilo.aviso("Cada jugador usa su propio equipo; el tablero se sincroniza en tiempo real.", Estilo.EXITO, Estilo.EXITO_TEXTO))
	var tarjeta_ayuda := Estilo.tarjeta("Conexión en red", ayuda)
	tarjeta_ayuda.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	centro.add_child(tarjeta_ayuda)

	_grupo_color.get_buttons()[0].button_pressed = true
	_grupo_avatar.get_buttons()[0].button_pressed = true


## `datos` puede traer: nombre, url, color y aviso (por ejemplo, el motivo de una desconexión).
func configurar(partida: Partida, lobby: ControladorLobby, datos: Dictionary) -> void:
	_lobby = lobby
	partida.error_recibido.connect(_on_error)
	_nombre.text = datos.get("nombre", "")
	_servidor.text = datos.get("url", "")
	for boton in _grupo_color.get_buttons():
		if boton.get_meta("valor") == datos.get("color", ""):
			boton.button_pressed = true
	if datos.has("aviso"):
		_mostrar_estado(datos.aviso, true)


func _on_unirse() -> void:
	if not _datos_validos():
		return
	_bloquear(true)
	_mostrar_estado("Conectando con %s..." % _servidor.text.strip_edges())
	_lobby.unirse_a_partida(_servidor.text.strip_edges(), _nombre.text.strip_edges(), _valor(_grupo_color), _valor(_grupo_avatar))


func _on_hospedar() -> void:
	if _nombre.text.strip_edges().is_empty():
		_mostrar_estado("Escribe tu nombre de usuario.", true)
		return
	_bloquear(true)
	_lobby.hospedar_partida(_nombre.text.strip_edges(), _valor(_grupo_color), _valor(_grupo_avatar))


func _on_error(texto: String) -> void:
	_bloquear(false)
	_mostrar_estado(texto, true)


func _datos_validos() -> bool:
	if _nombre.text.strip_edges().is_empty():
		_mostrar_estado("Escribe tu nombre de usuario.", true)
		return false
	if not _servidor.text.strip_edges().begins_with("ws"):
		_mostrar_estado("La dirección del servidor debe empezar con ws:// (por ejemplo ws://192.168.1.10:%d)." % Red.PUERTO, true)
		return false
	return true


func _bloquear(bloqueado: bool) -> void:
	_boton_unirse.disabled = bloqueado
	_boton_hospedar.disabled = bloqueado


func _mostrar_estado(texto: String, es_error := false) -> void:
	_estado.text = texto
	_estado.add_theme_color_override("font_color", Estilo.ERROR_TEXTO if es_error else Estilo.TEXTO_SUAVE)


func _opcion(icono: Control, texto: String, grupo: ButtonGroup, valor: Variant) -> Button:
	var boton := Button.new()
	boton.toggle_mode = true
	boton.button_group = grupo
	boton.set_meta("valor", valor)
	boton.custom_minimum_size = Vector2(0, 64)
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var contenido := VBoxContainer.new()
	contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(icono)
	contenido.add_child(centro)
	if texto != "":
		var label := Estilo.etiqueta(texto, 12, Estilo.TEXTO)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contenido.add_child(label)
	boton.add_child(contenido)
	if grupo == _grupo_color:
		boton.toggled.connect(func(presionado: bool) -> void:
			if presionado:
				for avatar in _avatares:
					avatar.color = Estilo.color_de(valor))
	return boton


static func _valor(grupo: ButtonGroup) -> Variant:
	var boton := grupo.get_pressed_button()
	return boton.get_meta("valor") if boton else null
