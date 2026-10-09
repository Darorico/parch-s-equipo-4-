class_name PanelAcciones
extends PanelContainer
## Controles del turno (Pantallas 03 y 04 del storyboard): dado, «Lanzar dado», «Fichas disponibles»,
## «Liberar ficha» y «Mover ficha». No decide nada: solo le pasa la intención del usuario al
## ControladorTurno. Qué botones están activos lo decide la VistaTablero según las señales del Modelo.
## Debajo de los botones muestra, en una sola línea, el último resultado que devolvió el Mock
## («Ficha movida N casillas», «¡Éxito! Sacó la ficha…») o el último error.
## Diseño: views/escenas/panel_acciones.tscn.

signal ficha_elegida(ficha_id: int)

@onready var dado: DadoVista = %Dado
@onready var boton_lanzar: Button = %BotonLanzar
@onready var boton_liberar: Button = %BotonLiberar
@onready var boton_mover: Button = %BotonMover
@onready var _titulo: Label = %Titulo
@onready var _resultado: Label = %Resultado
@onready var _linea_resultado: Label = %LineaResultado
@onready var _chips_contenedor: HBoxContainer = %Chips

var _chips: Array[Button] = []
var _grupo := ButtonGroup.new()
var _controlador: ControladorTurno
var _puede_lanzar := false
var _opciones := {}  # Últimas opciones mostradas, para restaurar tras un error.


func _ready() -> void:
	_grupo.allow_unpress = true
	for chip: Button in _chips_contenedor.get_children():
		chip.set_meta("ficha", _chips.size() + 1)
		chip.toggle_mode = true
		chip.button_group = _grupo
		chip.toggled.connect(_on_chip.bind(chip))
		_chips.append(chip)
	boton_lanzar.pressed.connect(_on_lanzar)
	boton_liberar.pressed.connect(_on_liberar)
	boton_mover.pressed.connect(_on_mover)
	boton_lanzar.disabled = true
	_linea_resultado.text = ""
	limpiar_opciones()


func configurar(controlador: ControladorTurno) -> void:
	_controlador = controlador


func mostrar_turno(es_mio: bool, nombre: String) -> void:
	_puede_lanzar = es_mio
	boton_lanzar.disabled = not es_mio
	boton_lanzar.text = "Lanzar dado" if es_mio else "Turno de %s" % nombre
	_titulo.text = "¡TU TURNO!" if es_mio else "TURNO DE %s" % nombre.to_upper()
	if es_mio:
		Sonidos.turno_propio()
	limpiar_opciones()


## Paso 1 del dado: solo lo hace rodar. Devuelve cuánto dura, para no mostrar nada más hasta que termine.
func animar_dado(valor: int) -> float:
	_resultado.text = "Lanzando el dado..."
	dado.animar(valor)
	return DadoVista.duracion_animacion()


## Paso 2 del dado: ya terminó de rodar, ahora se muestra el resultado.
func revelar_dado(valor: int, nombre: String, es_mio: bool) -> void:
	_resultado.text = ("Sacaste un %d." if es_mio else nombre + " sacó un %d.") % valor


func mostrar_opciones(movibles: Array, puede_liberar: bool) -> void:
	_opciones = {"movibles": movibles, "puede_liberar": puede_liberar}
	_puede_lanzar = false
	boton_lanzar.disabled = true
	_titulo.text = "ELIGE FICHA"
	for chip in _chips:
		chip.disabled = not chip.get_meta("ficha") in movibles
		chip.set_pressed_no_signal(false)
	boton_liberar.disabled = not puede_liberar
	boton_mover.disabled = true
	if movibles.size() == 1:
		seleccionar_ficha(movibles[0])


func limpiar_opciones() -> void:
	_opciones = {}
	for chip in _chips:
		chip.set_pressed_no_signal(false)
		chip.disabled = true
	boton_liberar.disabled = true
	boton_mover.disabled = true


## Última línea de resultado del Mock (o error, en rojo).
func mostrar_resultado(texto: String, es_error := false) -> void:
	_linea_resultado.text = texto
	_linea_resultado.add_theme_color_override("font_color", Estilo.ERROR_TEXTO if es_error else Estilo.TEXTO)


## Vuelve a habilitar lo que estaba disponible (por ejemplo, si el servidor rechazó la acción).
func restaurar() -> void:
	if not _opciones.is_empty():
		mostrar_opciones(_opciones.movibles, _opciones.puede_liberar)
	else:
		boton_lanzar.disabled = not _puede_lanzar


func seleccionar_ficha(ficha_id: int) -> void:
	for chip in _chips:
		if chip.get_meta("ficha") == ficha_id and not chip.disabled:
			chip.button_pressed = true


func _on_chip(presionado: bool, chip: Button) -> void:
	if presionado:
		boton_mover.disabled = false
		ficha_elegida.emit(chip.get_meta("ficha"))
	elif _grupo.get_pressed_button() == null:
		boton_mover.disabled = true
		ficha_elegida.emit(0)


func _on_lanzar() -> void:
	boton_lanzar.disabled = true
	_controlador.procesar_lanzamiento_dado()


func _on_liberar() -> void:
	_bloquear_opciones()
	_controlador.liberar_ficha()


func _on_mover() -> void:
	var chip := _grupo.get_pressed_button()
	if chip == null:
		return
	_bloquear_opciones()
	_controlador.mover_ficha(chip.get_meta("ficha"))


func _bloquear_opciones() -> void:
	for chip in _chips:
		chip.disabled = true
	boton_liberar.disabled = true
	boton_mover.disabled = true
