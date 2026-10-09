class_name PanelAcciones
extends PanelContainer
## Controles del turno (Pantallas 03 y 04 del storyboard): dado, «Lanzar dado», «Fichas disponibles»,
## «Liberar ficha» y «Mover ficha». No decide nada: solo le pasa la intención del usuario al
## ControladorTurno. Qué botones están activos lo decide la VistaTablero según las señales del Modelo.

signal ficha_elegida(ficha_id: int)

var dado := DadoVista.new()
var boton_lanzar := Button.new()
var boton_liberar := Button.new()
var boton_mover := Button.new()
var _titulo := Estilo.etiqueta("Dado", 18, Estilo.TEXTO, true)
var _resultado := Estilo.parrafo("Aún no se ha lanzado el dado.", 13)
var _seccion_fichas := VBoxContainer.new()
var _chips: Array[Button] = []
var _grupo := ButtonGroup.new()
var _controlador: ControladorTurno
var _puede_lanzar := false
var _opciones := {}  # Últimas opciones mostradas, para restaurar tras un error.


func _init() -> void:
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	add_child(columna)

	var fila_dado := HBoxContainer.new()
	fila_dado.add_theme_constant_override("separation", 14)
	fila_dado.add_child(dado)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(_titulo)
	textos.add_child(_resultado)
	fila_dado.add_child(textos)
	columna.add_child(fila_dado)

	boton_lanzar.text = "Lanzar dado"
	boton_lanzar.theme_type_variation = &"BotonPrimario"
	boton_lanzar.custom_minimum_size.y = 44
	boton_lanzar.disabled = true
	boton_lanzar.pressed.connect(_on_lanzar)
	columna.add_child(boton_lanzar)

	_seccion_fichas.add_theme_constant_override("separation", 8)
	_seccion_fichas.add_child(Estilo.rotulo("FICHAS DISPONIBLES"))
	var fila_chips := HBoxContainer.new()
	fila_chips.add_theme_constant_override("separation", 8)
	_grupo.allow_unpress = true
	for i in 4:
		var chip := Button.new()
		chip.text = str(i + 1)
		chip.tooltip_text = "Ficha %d" % (i + 1)
		chip.toggle_mode = true
		chip.button_group = _grupo
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.set_meta("ficha", i + 1)
		chip.disabled = true
		chip.toggled.connect(_on_chip.bind(chip))
		fila_chips.add_child(chip)
		_chips.append(chip)
	_seccion_fichas.add_child(fila_chips)

	var fila_botones := HBoxContainer.new()
	fila_botones.add_theme_constant_override("separation", 8)
	boton_liberar.text = "Liberar ficha"
	boton_liberar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton_liberar.pressed.connect(_on_liberar)
	boton_mover.text = "Mover ficha"
	boton_mover.theme_type_variation = &"BotonPrimario"
	boton_mover.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton_mover.pressed.connect(_on_mover)
	fila_botones.add_child(boton_liberar)
	fila_botones.add_child(boton_mover)
	_seccion_fichas.add_child(fila_botones)
	columna.add_child(_seccion_fichas)
	limpiar_opciones()


func configurar(controlador: ControladorTurno) -> void:
	_controlador = controlador


func mostrar_turno(es_mio: bool, nombre: String) -> void:
	_puede_lanzar = es_mio
	boton_lanzar.disabled = not es_mio
	boton_lanzar.text = "Lanzar dado" if es_mio else "Turno de %s" % nombre
	_titulo.text = "¡Es tu turno!" if es_mio else "Turno de %s" % nombre
	limpiar_opciones()


func mostrar_dado(valor: int, nombre: String, es_mio: bool) -> void:
	dado.animar(valor)
	_resultado.text = ("Sacaste un %d." if es_mio else nombre + " sacó un %d.") % valor


func mostrar_opciones(movibles: Array, puede_liberar: bool) -> void:
	_opciones = {"movibles": movibles, "puede_liberar": puede_liberar}
	_puede_lanzar = false
	boton_lanzar.disabled = true
	_titulo.text = "Elige una ficha válida"
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
