class_name Estilo
extends RefCounted
## Dirección de arte «cuaderno escolar»: paleta de crayones, fuente Pangolin y tema de la interfaz
## dibujado a mano (StyleBoxCrayon). Todas las pantallas toman sus piezas visuales de aquí.

const FUENTE := preload("res://assets/fuentes/Pangolin-Regular.ttf")

const PAPEL := Color("#fbfaf6")
const LAPIZ := Garabato.LAPIZ
const TEXTO := Color("#22304a")        # lápiz azul marino
const TEXTO_SUAVE := Color("#4f5a6e")
const TITULO := Color("#c8312a")       # crayón rojo de los títulos
const PRIMARIO := Color("#2f6fd6")     # crayón azul de los botones
const PRIMARIO_OSCURO := Color("#2156b0")
const TEXTO_BOTON := Color("#ffd23f")  # letras amarillas sobre el botón azul
const PRIMARIO_SUAVE := Color("#8ec9ef")
const RESALTADOR := Color("#ffe14d")
const EXITO := Color("#8fd16e")
const EXITO_TEXTO := Color("#1e5a27")
const ERROR_TEXTO := Color("#c8312a")
const DESHABILITADO := Color("#c9c9c4")
const GRIS_SEGURO := Color("#9d9d98")

const COLORES := {
	"rojo": Color("#d93a2b"),
	"verde": Color("#2e9e3e"),
	"amarillo": Color("#f2c416"),
	"azul": Color("#2f7fd6"),
}
const NOMBRES := {"rojo": "Rojo", "verde": "Verde", "amarillo": "Amarillo", "azul": "Azul"}

static var _negrita: FontVariation


static func color_de(nombre_color: String) -> Color:
	return COLORES.get(nombre_color, Color.GRAY)


static func fuente() -> Font:
	return FUENTE


## Pangolin «repasada»: la misma fuente con trazo más grueso, para títulos y botones.
static func negrita() -> Font:
	if _negrita == null:
		_negrita = FontVariation.new()
		_negrita.base_font = FUENTE
		_negrita.variation_embolden = 0.6
	return _negrita


## Caja dibujada a mano: relleno de crayón (o transparente) y borde de lápiz (o sin borde).
static func caja(relleno: Color, borde := Color.TRANSPARENT, margen := 12.0) -> StyleBoxCrayon:
	return StyleBoxCrayon.new(relleno, borde, margen)


static func crear_tema() -> Theme:
	var tema := Theme.new()
	tema.default_font = FUENTE
	tema.default_font_size = 18
	tema.set_color("font_color", "Label", TEXTO)

	tema.set_stylebox("panel", "PanelContainer", caja(Color(1, 1, 1, 0.0), LAPIZ, 18.0))

	_estilos_boton(tema, "Button", Color(1, 1, 1, 0.0), Color(RESALTADOR, 0.55), PRIMARIO_SUAVE, TEXTO, TEXTO)
	tema.set_type_variation("BotonPrimario", "Button")
	_estilos_boton(tema, "BotonPrimario", PRIMARIO, PRIMARIO_OSCURO, PRIMARIO_OSCURO, TEXTO_BOTON, TEXTO_BOTON)
	tema.set_font("font", "BotonPrimario", negrita())
	tema.set_font_size("font_size", "BotonPrimario", 22)

	var campo := caja(Color(1, 1, 1, 0.0), LAPIZ, 10.0)
	campo.doble_trazo = false
	var campo_foco := caja(Color(PRIMARIO_SUAVE, 0.25), PRIMARIO, 10.0)
	tema.set_stylebox("normal", "LineEdit", campo)
	tema.set_stylebox("focus", "LineEdit", campo_foco)
	tema.set_color("font_color", "LineEdit", TEXTO)
	tema.set_color("font_placeholder_color", "LineEdit", TEXTO_SUAVE)
	tema.set_color("caret_color", "LineEdit", TEXTO)
	return tema


static func _estilos_boton(tema: Theme, tipo: String, normal: Color, hover: Color, presionado: Color,
		texto: Color, texto_presionado: Color) -> void:
	tema.set_stylebox("normal", tipo, caja(normal, LAPIZ, 10.0))
	tema.set_stylebox("hover", tipo, caja(hover, LAPIZ, 10.0))
	tema.set_stylebox("pressed", tipo, caja(presionado, PRIMARIO_OSCURO, 10.0))
	tema.set_stylebox("hover_pressed", tipo, caja(presionado, PRIMARIO_OSCURO, 10.0))
	tema.set_stylebox("disabled", tipo, caja(Color(DESHABILITADO, 0.45), Color(LAPIZ, 0.35), 10.0))
	tema.set_stylebox("focus", tipo, StyleBoxEmpty.new())
	for estado in ["font_color", "font_hover_color", "font_focus_color"]:
		tema.set_color(estado, tipo, texto)
	tema.set_color("font_pressed_color", tipo, texto_presionado)
	tema.set_color("font_hover_pressed_color", tipo, texto_presionado)
	tema.set_color("font_disabled_color", tipo, Color(TEXTO_SUAVE, 0.6))


static func etiqueta(texto: String, tamano := 18, color := TEXTO, en_negrita := false) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", tamano)
	label.add_theme_color_override("font_color", color)
	if en_negrita:
		label.add_theme_font_override("font", negrita())
	return label


## Texto largo que se ajusta al ancho disponible.
static func parrafo(texto: String, tamano := 17, color := TEXTO) -> Label:
	var label := etiqueta(texto, tamano, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


## Rótulo de campo en mayúsculas («NOMBRE DE USUARIO», «COLOR DE FICHA»…).
static func rotulo(texto: String) -> Label:
	return etiqueta(texto.to_upper(), 16, TEXTO)


## Rótulo marcado con resaltador amarillo («REGLAS ACTIVAS», «FICHAS DISPONIBLES»).
static func resaltado(texto: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var estilo := caja(Color(RESALTADOR, 0.8), Color.TRANSPARENT, 2.0)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	panel.add_theme_stylebox_override("panel", estilo)
	panel.add_child(etiqueta(texto.to_upper(), 18, TEXTO, true))
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## Mancha de crayón con un texto corto («ESPERANDO», «LISTO», «TURNO»).
static func pildora(texto: String, fondo: Color, color_texto: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var estilo := caja(fondo, Color.TRANSPARENT, 3.0)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	panel.add_theme_stylebox_override("panel", estilo)
	panel.add_child(etiqueta(texto.to_upper(), 14, color_texto, true))
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


## Recuadro coloreado a crayón con un texto (aviso celeste, verde, etc.).
static func aviso(texto: String, fondo := PRIMARIO_SUAVE, color_texto := TEXTO) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", caja(Color(fondo, 0.7), Color.TRANSPARENT, 10.0))
	panel.add_child(parrafo(texto, 16, color_texto))
	return panel


## Recuadro de lápiz con título en crayón rojo y el contenido debajo.
static func tarjeta(titulo: String, contenido: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	if titulo != "":
		columna.add_child(etiqueta(titulo.to_upper(), 30, TITULO, true))
	columna.add_child(contenido)
	panel.add_child(columna)
	return panel


## Encabezado de pantalla: número y sección a lápiz, título grande en crayón rojo y el logo.
## Los textos se pueden cambiar después con los nodos «Numero», «Seccion», «Titulo» y «Subtitulo».
static func encabezado(numero: String, seccion: String, titulo: String, subtitulo: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 0)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(textos)

	var linea := HBoxContainer.new()
	linea.add_theme_constant_override("separation", 8)
	var pill := pildora(numero, LAPIZ, PAPEL)
	pill.get_child(0).name = "Numero"
	linea.add_child(pill)
	var label_seccion := etiqueta(seccion, 16, PRIMARIO, true)
	label_seccion.name = "Seccion"
	linea.add_child(label_seccion)
	textos.add_child(linea)

	var label_titulo := etiqueta(titulo, 36, TITULO, true)
	label_titulo.name = "Titulo"
	textos.add_child(label_titulo)
	var label_subtitulo := etiqueta(subtitulo, 17, TEXTO_SUAVE)
	label_subtitulo.name = "Subtitulo"
	textos.add_child(label_subtitulo)

	var logo := resaltado("Parchís Club")
	logo.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	fila.add_child(logo)
	return fila


static func cambiar_encabezado(encabezado_actual: Control, numero: String, seccion: String, titulo: String, subtitulo: String) -> void:
	encabezado_actual.find_child("Numero", true, false).text = numero.to_upper()
	encabezado_actual.find_child("Seccion", true, false).text = seccion
	encabezado_actual.find_child("Titulo", true, false).text = titulo
	encabezado_actual.find_child("Subtitulo", true, false).text = subtitulo


static func vaciar(contenedor: Node) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()
