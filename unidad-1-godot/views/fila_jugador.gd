class_name FilaJugador
extends PanelContainer
## Fila de un jugador: avatar, nombre, detalle y una etiqueta («LISTO», «ESPERANDO», «TURNO»).
## La usan la sala de espera y el panel «Jugadores». Su diseño se edita en views/escenas/fila_jugador.tscn.

const ESCENA := "res://views/escenas/fila_jugador.tscn"

@onready var _avatar: AvatarIcono = %Avatar
@onready var _nombre: Label = %Nombre
@onready var _detalle: Label = %Detalle
@onready var _etiqueta: PanelContainer = %Etiqueta
@onready var _texto_etiqueta: Label = %TextoEtiqueta


static func crear() -> FilaJugador:
	return load(ESCENA).instantiate()


## Llénala después de agregarla al árbol. `etiqueta` vacía oculta la etiqueta.
func mostrar(datos: Dictionary, es_tu: bool, detalle: String, etiqueta := "", fondo_etiqueta := Estilo.PRIMARIO_SUAVE,
		color_etiqueta := Estilo.TEXTO, resaltada := false) -> void:
	_avatar.color = Estilo.color_de(datos.color)
	_avatar.forma = datos.avatar
	_nombre.text = datos.nombre + (" (tú)" if es_tu else "")
	_nombre.add_theme_color_override("font_color", Estilo.color_de(datos.color).darkened(0.25))
	_detalle.text = detalle
	_etiqueta.visible = etiqueta != ""
	_texto_etiqueta.text = etiqueta.to_upper()
	_texto_etiqueta.add_theme_color_override("font_color", color_etiqueta)
	_etiqueta.add_theme_stylebox_override("panel", _caja_etiqueta(fondo_etiqueta))
	if resaltada:
		add_theme_stylebox_override("panel", Estilo.caja(Color(Estilo.RESALTADOR, 0.55), Color.TRANSPARENT, 6.0))


static func _caja_etiqueta(fondo: Color) -> StyleBoxCrayon:
	var estilo := Estilo.caja(fondo, Color.TRANSPARENT, 3.0)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	return estilo
