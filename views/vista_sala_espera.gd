class_name VistaSalaEspera
extends MarginContainer
## Pantalla 02 del storyboard: Sala de espera / Arranque (CU02 Confirmar Estado y CU03 Iniciar Partida).
## OBSERVA al Modelo (jugadores_actualizados) para pintar la lista; el botón «Listo» va al ControladorLobby.

var _lobby: ControladorLobby
var _mi_id := 0
var _estoy_listo := false
var _lista := VBoxContainer.new()
var _resumen := Label.new()
var _conectados := Estilo.etiqueta("", 15, Estilo.PRIMARIO, true)
var _boton_listo := Button.new()
var _estado := Estilo.parrafo("", 13, Estilo.ERROR_TEXTO)


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		add_theme_constant_override("margin_" + lado, 40)
	for lado in ["top", "bottom"]:
		add_theme_constant_override("margin_" + lado, 26)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 22)
	add_child(raiz)
	raiz.add_child(Estilo.encabezado("02", "SALA DE ESPERA / ARRANQUE", "Espera a que todos confirmen",
			"De 2 a 4 jugadores. La partida arranca cuando todos los registrados están listos."))

	var centro := HBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 20)
	raiz.add_child(centro)

	var sala := VBoxContainer.new()
	sala.custom_minimum_size.x = 460
	sala.add_theme_constant_override("separation", 10)
	_lista.add_theme_constant_override("separation", 6)
	sala.add_child(_lista)
	var caja_resumen := PanelContainer.new()
	caja_resumen.add_theme_stylebox_override("panel", Estilo.caja(Estilo.PRIMARIO_SUAVE, 10, Color.TRANSPARENT, 10))
	_resumen.add_theme_color_override("font_color", Estilo.PRIMARIO)
	_resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja_resumen.add_child(_resumen)
	sala.add_child(caja_resumen)
	_boton_listo.text = "Listo"
	_boton_listo.theme_type_variation = &"BotonPrimario"
	_boton_listo.custom_minimum_size.y = 44
	_boton_listo.pressed.connect(_on_listo)
	sala.add_child(_boton_listo)
	sala.add_child(_estado)
	centro.add_child(Estilo.tarjeta("Sala de espera", sala))

	var estado_partida := VBoxContainer.new()
	estado_partida.custom_minimum_size.x = 320
	estado_partida.add_theme_constant_override("separation", 10)
	estado_partida.add_child(_conectados)
	estado_partida.add_child(Estilo.rotulo("REGLAS ACTIVAS"))
	estado_partida.add_child(Estilo.parrafo("• De 2 a 4 jugadores pueden jugar."))
	estado_partida.add_child(Estilo.parrafo("• Todos deben confirmar «Listo» antes de arrancar."))
	estado_partida.add_child(Estilo.parrafo("• El sistema elige al azar quién empieza; los turnos siguen el sentido horario."))
	estado_partida.add_child(Estilo.aviso("Al iniciar, todos ven el mismo tablero y el turno del primer jugador.", Estilo.EXITO, Estilo.EXITO_TEXTO))
	var tarjeta_estado := Estilo.tarjeta("Estado de la partida", estado_partida)
	tarjeta_estado.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	centro.add_child(tarjeta_estado)


func configurar(partida: Partida, lobby: ControladorLobby, mi_id: int) -> void:
	_lobby = lobby
	_mi_id = mi_id
	partida.jugadores_actualizados.connect(_on_jugadores_actualizados)
	partida.error_recibido.connect(_on_error)


func _on_jugadores_actualizados(jugadores: Array) -> void:
	Estilo.vaciar(_lista)
	var listos := 0
	for datos: Dictionary in jugadores:
		if datos.listo:
			listos += 1
		if datos.id == _mi_id:
			_estoy_listo = datos.listo
		_lista.add_child(_fila(datos))
	_resumen.text = "%d/%d listos · se necesitan al menos %d jugadores y que todos confirmen." % [listos, jugadores.size(), Partida.MIN_JUGADORES]
	_conectados.text = "%d de %d jugadores conectados" % [jugadores.size(), Partida.MAX_JUGADORES]
	_boton_listo.text = "Cancelar «Listo»" if _estoy_listo else "Listo"
	_boton_listo.theme_type_variation = &"" if _estoy_listo else &"BotonPrimario"
	_boton_listo.disabled = false


func _on_listo() -> void:
	_boton_listo.disabled = true
	_estado.text = ""
	_lobby.confirmar_estado(not _estoy_listo)


func _on_error(texto: String) -> void:
	_boton_listo.disabled = false
	_estado.text = texto


func _fila(datos: Dictionary) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.add_child(AvatarIcono.new(Estilo.color_de(datos.color), datos.avatar, 34))
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 0)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_child(Estilo.etiqueta(datos.nombre + (" (tú)" if datos.id == _mi_id else ""), 15, Estilo.TEXTO, true))
	textos.add_child(Estilo.etiqueta("%s · %s" % [Estilo.NOMBRES[datos.color], "listo" if datos.listo else "esperando"], 12, Estilo.TEXTO_SUAVE))
	fila.add_child(textos)
	if datos.listo:
		fila.add_child(Estilo.pildora("Listo", Estilo.EXITO, Estilo.EXITO_TEXTO))
	else:
		fila.add_child(Estilo.pildora("Esperando", Color("#eceff4"), Estilo.TEXTO_SUAVE))
	return fila
