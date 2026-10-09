class_name PanelAcciones
extends PanelContainer
## Controles del turno (Pantallas 03 y 04 del storyboard). No decide nada: solo le pasa la intención
## del usuario al ControladorTurno. Qué se puede hacer lo decide la VistaTablero según las señales del Modelo.
##
## Cómo se juega:
##   - Para lanzar, se hace clic en el DADO (se resalta cuando es tu turno).
##   - Las fichas se eligen haciendo clic en el TABLERO.
##       · Si no salió 5: al hacer clic en una ficha resaltada, se mueve.
##       · Si salió 5: aparecen «Liberar ficha» y «Mover ficha». «Liberar» queda sombreado si ya no
##         quedan fichas en casa; para mover, primero se hace clic en la ficha y luego en «Mover ficha».
## Debajo se muestra en una sola línea el último resultado del Mock o el último error.
## Diseño: views/escenas/panel_acciones.tscn.

signal ficha_elegida(ficha_id: int)

enum Modo { ESPERANDO, CLIC_EN_TABLERO, CON_CINCO }

const VALOR_PARA_SALIR := 5

@onready var dado: DadoVista = %Dado
@onready var boton_liberar: Button = %BotonLiberar
@onready var boton_mover: Button = %BotonMover
# Opcionales: si la escena no los tiene, el panel funciona igual.
@onready var _titulo: Label = get_node_or_null("%Titulo")
@onready var _resultado: Label = get_node_or_null("%Resultado")
@onready var _linea_resultado: Label = get_node_or_null("%LineaResultado")

var _controlador: ControladorTurno
var _modo := Modo.ESPERANDO
var _puede_lanzar := false
var _ultimo_valor := 0
var _seleccionada := 0
var _opciones := {}  # Últimas opciones mostradas, para restaurar tras un error.


func _ready() -> void:
	# El dado es el botón para lanzar y las fichas se eligen en el tablero: los controles antiguos
	# («Lanzar dado» y los chips 1-4), si siguen en la escena, se ocultan.
	for viejo in ["%BotonLanzar", "%Chips", "%SeccionFichas"]:
		var nodo := get_node_or_null(viejo) as CanvasItem
		if nodo:
			nodo.visible = false
	var rotulo := find_child("RotuloFichas", true, false) as CanvasItem
	if rotulo:
		rotulo.visible = false
	dado.presionado.connect(_on_lanzar)
	boton_liberar.pressed.connect(_on_liberar)
	boton_mover.pressed.connect(_on_mover)
	_texto(_linea_resultado, "")
	limpiar_opciones()


func configurar(controlador: ControladorTurno) -> void:
	_controlador = controlador


func mostrar_turno(es_mio: bool, nombre: String) -> void:
	_puede_lanzar = es_mio
	dado.activo = es_mio
	_texto(_titulo, "¡TU TURNO!" if es_mio else "TURNO DE %s" % nombre.to_upper())
	_texto(_resultado, "Haz clic en el dado para lanzarlo." if es_mio else "Esperando a que %s lance el dado." % nombre)
	if es_mio:
		Sonidos.turno_propio()
	limpiar_opciones()


func terminar_partida() -> void:
	_puede_lanzar = false
	dado.activo = false
	_texto(_titulo, "PARTIDA TERMINADA")
	limpiar_opciones()


## Paso 1 del dado: solo lo hace rodar. Devuelve cuánto dura, para no mostrar nada más hasta que termine.
func animar_dado(valor: int) -> float:
	_ultimo_valor = valor
	dado.activo = false
	_texto(_resultado, "Lanzando el dado...")
	dado.animar(valor)
	return DadoVista.duracion_animacion()


## Paso 2 del dado: ya terminó de rodar, ahora se muestra el resultado.
func revelar_dado(valor: int, nombre: String, es_mio: bool) -> void:
	_texto(_resultado, ("Sacaste un %d." if es_mio else nombre + " sacó un %d.") % valor)


## Es tu turno de elegir. Con 5 aparecen los botones; con otro número se elige con un clic en el tablero.
func mostrar_opciones(movibles: Array, puede_liberar: bool) -> void:
	_opciones = {"movibles": movibles, "puede_liberar": puede_liberar}
	_puede_lanzar = false
	dado.activo = false
	_seleccionada = 0
	if _ultimo_valor == VALOR_PARA_SALIR:
		_modo = Modo.CON_CINCO
		boton_liberar.visible = true
		boton_mover.visible = true
		boton_liberar.disabled = not puede_liberar
		boton_mover.disabled = true
		_texto(_titulo, "¡SACASTE 5!")
		if movibles.is_empty():
			_texto(_resultado, "Libera una ficha de tu casa.")
		elif puede_liberar:
			_texto(_resultado, "Libera una ficha, o haz clic en una del tablero y pulsa «Mover ficha».")
		else:
			_texto(_resultado, "Ya no hay fichas en casa: haz clic en una del tablero y pulsa «Mover ficha».")
	else:
		_modo = Modo.CLIC_EN_TABLERO
		_ocultar_botones()
		_texto(_titulo, "ELIGE FICHA")
		_texto(_resultado, "Sacaste un %d: haz clic en la ficha que quieres mover." % _ultimo_valor)


func limpiar_opciones() -> void:
	_opciones = {}
	_modo = Modo.ESPERANDO
	_seleccionada = 0
	_ocultar_botones()


## Última línea de resultado del Mock (o error, en rojo).
func mostrar_resultado(texto: String, es_error := false) -> void:
	_texto(_linea_resultado, texto)
	if _linea_resultado:
		_linea_resultado.add_theme_color_override("font_color", Estilo.ERROR_TEXTO if es_error else Estilo.TEXTO)


## Vuelve a habilitar lo que estaba disponible (por ejemplo, si el servidor rechazó la acción).
func restaurar() -> void:
	if not _opciones.is_empty():
		mostrar_opciones(_opciones.movibles, _opciones.puede_liberar)
	else:
		dado.activo = _puede_lanzar


## Clic en una ficha del tablero (solo llegan las fichas resaltadas, es decir, las que se pueden mover).
func seleccionar_ficha(ficha_id: int) -> void:
	if _opciones.is_empty() or not ficha_id in _opciones.movibles:
		return
	match _modo:
		Modo.CLIC_EN_TABLERO:
			_bloquear()
			_controlador.mover_ficha(ficha_id)
		Modo.CON_CINCO:
			_seleccionada = ficha_id
			boton_mover.disabled = false
			ficha_elegida.emit(ficha_id)


func _on_lanzar() -> void:
	_puede_lanzar = false
	_controlador.procesar_lanzamiento_dado()


func _on_liberar() -> void:
	_bloquear()
	_controlador.liberar_ficha()


func _on_mover() -> void:
	if _seleccionada == 0:
		return
	var ficha := _seleccionada
	_bloquear()
	_controlador.mover_ficha(ficha)


## Evita dobles clics mientras el servidor responde.
func _bloquear() -> void:
	_modo = Modo.ESPERANDO
	boton_liberar.disabled = true
	boton_mover.disabled = true


func _ocultar_botones() -> void:
	boton_liberar.visible = false
	boton_mover.visible = false


static func _texto(label: Label, texto: String) -> void:
	if label:
		label.text = texto
