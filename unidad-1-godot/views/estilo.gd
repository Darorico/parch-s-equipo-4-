@tool
class_name Estilo
extends RefCounted
## Dirección de arte «cuaderno escolar»: paleta de crayones, fuente Pangolin y piezas visuales que
## se crean desde código. El tema de la interfaz está en views/tema/tema_cuaderno.tres (se edita en
## el editor) y el diseño de cada pantalla en views/escenas/.

const FUENTE := preload("res://assets/fuentes/Pangolin-Regular.ttf")
## Pangolin «repasada» (más gruesa). Es un recurso para que las escenas y el tema la compartan.
const RUTA_NEGRITA := "res://views/tema/pangolin_negrita.tres"
## Tema de toda la interfaz (también es el tema del proyecto, así se ve igual en el editor).
const RUTA_TEMA := "res://views/tema/tema_cuaderno.tres"

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
		if ResourceLoader.exists(RUTA_NEGRITA):
			_negrita = load(RUTA_NEGRITA)
		else:
			_negrita = FontVariation.new()
			_negrita.base_font = FUENTE
			_negrita.variation_embolden = 0.6
	return _negrita


## Caja dibujada a mano: relleno de crayón (o transparente) y borde de lápiz (o sin borde).
static func caja(relleno: Color, borde := Color.TRANSPARENT, margen := 12.0) -> StyleBoxCrayon:
	return StyleBoxCrayon.new(relleno, borde, margen)


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


## Si la pantalla no tiene encabezado (o le falta alguna parte), simplemente no hace nada.
static func cambiar_encabezado(encabezado_actual: Control, numero: String, seccion: String, titulo: String, subtitulo: String) -> void:
	if encabezado_actual == null:
		return
	for parte in [["Numero", numero.to_upper()], ["Seccion", seccion], ["Titulo", titulo], ["Subtitulo", subtitulo]]:
		var label := encabezado_actual.find_child(parte[0], true, false) as Label
		if label:
			label.text = parte[1]



static func vaciar(contenedor: Node) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()
