class_name Estilo
extends RefCounted
## Paleta, tema y piezas visuales comunes, tomadas del storyboard («PARCHÍS CLUB»).

const FONDO := Color("#eef1f6")
const TARJETA := Color("#ffffff")
const BORDE := Color("#dfe4ec")
const TEXTO := Color("#1c2333")
const TEXTO_SUAVE := Color("#6a7386")
const PRIMARIO := Color("#2f6fed")
const PRIMARIO_HOVER := Color("#2459c9")
const PRIMARIO_SUAVE := Color("#e8f0fe")
const AVISO := Color("#fff7dc")
const AVISO_BORDE := Color("#f1dc96")
const EXITO := Color("#e6f6ec")
const EXITO_TEXTO := Color("#1f7a3d")
const ERROR_TEXTO := Color("#c0392b")

const COLORES := {
	"verde": Color("#2fa84f"),
	"amarillo": Color("#f2c12e"),
	"azul": Color("#2f80ed"),
	"rojo": Color("#e8483b"),
}
const NOMBRES := {"verde": "Verde", "amarillo": "Amarillo", "azul": "Azul", "rojo": "Rojo"}

static var _negrita: FontVariation


static func color_de(nombre_color: String) -> Color:
	return COLORES.get(nombre_color, Color.GRAY)


static func negrita() -> Font:
	if _negrita == null:
		_negrita = FontVariation.new()
		_negrita.base_font = ThemeDB.fallback_font
		_negrita.variation_embolden = 0.9
	return _negrita


static func caja(fondo: Color, radio := 14, borde := Color.TRANSPARENT, margen := 16) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.set_corner_radius_all(radio)
	if borde.a > 0.0:
		estilo.border_color = borde
		estilo.set_border_width_all(1)
	estilo.set_content_margin_all(margen)
	estilo.anti_aliasing = true
	return estilo


static func crear_tema() -> Theme:
	var tema := Theme.new()
	tema.default_font_size = 15
	tema.set_color("font_color", "Label", TEXTO)

	var tarjeta := caja(TARJETA, 16, BORDE, 18)
	tarjeta.shadow_color = Color(0.1, 0.15, 0.3, 0.06)
	tarjeta.shadow_size = 8
	tarjeta.shadow_offset = Vector2(0, 2)
	tema.set_stylebox("panel", "PanelContainer", tarjeta)

	_estilos_boton(tema, "Button", TARJETA, Color("#f4f6fa"), PRIMARIO_SUAVE, BORDE, TEXTO, PRIMARIO)
	tema.set_type_variation("BotonPrimario", "Button")
	_estilos_boton(tema, "BotonPrimario", PRIMARIO, PRIMARIO_HOVER, PRIMARIO_HOVER, PRIMARIO, Color.WHITE, Color.WHITE)

	tema.set_stylebox("normal", "LineEdit", caja(TARJETA, 10, BORDE, 10))
	tema.set_stylebox("focus", "LineEdit", caja(Color.TRANSPARENT, 10, PRIMARIO, 10))
	tema.set_color("font_color", "LineEdit", TEXTO)
	tema.set_color("font_placeholder_color", "LineEdit", TEXTO_SUAVE)
	return tema


static func _estilos_boton(tema: Theme, tipo: String, normal: Color, hover: Color, presionado: Color,
		borde: Color, texto: Color, texto_presionado: Color) -> void:
	tema.set_stylebox("normal", tipo, caja(normal, 10, borde, 10))
	tema.set_stylebox("hover", tipo, caja(hover, 10, borde, 10))
	tema.set_stylebox("pressed", tipo, caja(presionado, 10, PRIMARIO, 10))
	tema.set_stylebox("hover_pressed", tipo, caja(presionado, 10, PRIMARIO, 10))
	tema.set_stylebox("disabled", tipo, caja(Color("#eceff4"), 10, BORDE, 10))
	tema.set_stylebox("focus", tipo, StyleBoxEmpty.new())
	for estado in ["font_color", "font_hover_color", "font_focus_color"]:
		tema.set_color(estado, tipo, texto)
	tema.set_color("font_pressed_color", tipo, texto_presionado)
	tema.set_color("font_hover_pressed_color", tipo, texto_presionado)
	tema.set_color("font_disabled_color", tipo, Color("#a3aab8"))


static func etiqueta(texto: String, tamano := 15, color := TEXTO, en_negrita := false) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", tamano)
	label.add_theme_color_override("font_color", color)
	if en_negrita:
		label.add_theme_font_override("font", negrita())
	return label


## Texto largo que se ajusta al ancho disponible.
static func parrafo(texto: String, tamano := 14, color := TEXTO_SUAVE) -> Label:
	var label := etiqueta(texto, tamano, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


## Rótulo pequeño en mayúsculas («COLOR DE FICHA», «FICHAS DISPONIBLES»…).
static func rotulo(texto: String) -> Label:
	return etiqueta(texto, 12, TEXTO_SUAVE, true)


static func pildora(texto: String, fondo: Color, color_texto: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var estilo := caja(fondo, 20, Color.TRANSPARENT, 3)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	panel.add_theme_stylebox_override("panel", estilo)
	panel.add_child(etiqueta(texto, 12, color_texto, true))
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## Caja de color con un texto (avisos azules, reglas amarillas, confirmaciones verdes).
static func aviso(texto: String, fondo := PRIMARIO_SUAVE, color_texto := PRIMARIO) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", caja(fondo, 10, Color.TRANSPARENT, 10))
	panel.add_child(parrafo(texto, 13, color_texto))
	return panel


## Tarjeta blanca con título y el contenido debajo.
static func tarjeta(titulo: String, contenido: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	if titulo != "":
		columna.add_child(etiqueta(titulo, 18, TEXTO, true))
	columna.add_child(contenido)
	panel.add_child(columna)
	return panel


## Encabezado de pantalla como en el storyboard: número, sección, título, subtítulo y logo.
## Los textos se pueden cambiar después con los nodos «Numero», «Seccion», «Titulo» y «Subtitulo».
static func encabezado(numero: String, seccion: String, titulo: String, subtitulo: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 2)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(textos)

	var linea := HBoxContainer.new()
	linea.add_theme_constant_override("separation", 8)
	var pill := pildora(numero, TEXTO, Color.WHITE)
	pill.get_child(0).name = "Numero"
	linea.add_child(pill)
	var label_seccion := etiqueta(seccion, 12, PRIMARIO, true)
	label_seccion.name = "Seccion"
	linea.add_child(label_seccion)
	textos.add_child(linea)

	var label_titulo := etiqueta(titulo, 28, TEXTO, true)
	label_titulo.name = "Titulo"
	textos.add_child(label_titulo)
	var label_subtitulo := etiqueta(subtitulo, 14, TEXTO_SUAVE)
	label_subtitulo.name = "Subtitulo"
	textos.add_child(label_subtitulo)

	var logo := etiqueta("PARCHÍS CLUB", 16, TEXTO, true)
	logo.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	fila.add_child(logo)
	return fila


static func cambiar_encabezado(encabezado_actual: Control, numero: String, seccion: String, titulo: String, subtitulo: String) -> void:
	encabezado_actual.find_child("Numero", true, false).text = numero
	encabezado_actual.find_child("Seccion", true, false).text = seccion
	encabezado_actual.find_child("Titulo", true, false).text = titulo
	encabezado_actual.find_child("Subtitulo", true, false).text = subtitulo


static func vaciar(contenedor: Node) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()
