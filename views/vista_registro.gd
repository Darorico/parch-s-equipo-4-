class_name VistaRegistro
extends Control
## Pantalla 01 del storyboard: Registro / Membresía (CU01 Registrar Jugador).
## Manda la acción al ControladorLobby y observa al Modelo para mostrar los errores.
## Diseño: views/escenas/vista_registro.tscn.

@onready var _nombre: LineEdit = %Nombre
@onready var _servidor: LineEdit = %Servidor
@onready var _opciones_color: HBoxContainer = %OpcionesColor
@onready var _opciones_avatar: HBoxContainer = %OpcionesAvatar
@onready var _boton_unirse: Button = %BotonUnirse
@onready var _boton_hospedar: Button = %BotonHospedar
@onready var _estado: Label = %Estado

var _lobby: ControladorLobby
var _grupo_color := ButtonGroup.new()
var _grupo_avatar := ButtonGroup.new()


func _ready() -> void:
	for boton: Button in _opciones_color.get_children():
		boton.button_group = _grupo_color
		boton.toggled.connect(_on_color_elegido.bind(boton))
	for boton: Button in _opciones_avatar.get_children():
		boton.button_group = _grupo_avatar
	_servidor.placeholder_text = "ws://IP-del-servidor:%d" % Red.PUERTO
	_boton_hospedar.visible = not OS.has_feature("web")
	_boton_unirse.pressed.connect(_on_unirse)
	_boton_hospedar.pressed.connect(_on_hospedar)
	_grupo_color.get_buttons()[0].button_pressed = true
	_grupo_avatar.get_buttons()[0].button_pressed = true


## Se llama después de agregar la vista al árbol.
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


func _on_color_elegido(presionado: bool, boton: Button) -> void:
	if not presionado:
		return
	for opcion in _opciones_avatar.get_children():
		var icono := opcion.get_node_or_null("Contenido/Centro/Icono") as AvatarIcono
		if icono:
			icono.color = Estilo.color_de(boton.get_meta("valor"))


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
	_estado.add_theme_color_override("font_color", Estilo.ERROR_TEXTO if es_error else Estilo.TEXTO)


static func _valor(grupo: ButtonGroup) -> Variant:
	var boton := grupo.get_pressed_button()
	return boton.get_meta("valor") if boton else null
