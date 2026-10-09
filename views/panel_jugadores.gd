class_name PanelJugadores
extends PanelContainer
## Panel «Jugadores» del storyboard: avatar, nombre, color y fichas en meta de cada jugador.
## Resalta claramente al jugador al que le corresponde el turno.

var _filas := VBoxContainer.new()
var _texto_turno := Label.new()
var _jugadores: Array = []
var _mi_id := 0
var _turno_id := 0


func _init() -> void:
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	add_child(columna)
	columna.add_child(Estilo.etiqueta("Jugadores", 18, Estilo.TEXTO, true))
	_filas.add_theme_constant_override("separation", 4)
	columna.add_child(_filas)

	var caja_turno := PanelContainer.new()
	caja_turno.add_theme_stylebox_override("panel", Estilo.caja(Estilo.PRIMARIO_SUAVE, 10, Color.TRANSPARENT, 10))
	_texto_turno.add_theme_color_override("font_color", Estilo.PRIMARIO)
	_texto_turno.add_theme_font_override("font", Estilo.negrita())
	_texto_turno.add_theme_font_size_override("font_size", 14)
	_texto_turno.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja_turno.add_child(_texto_turno)
	columna.add_child(caja_turno)


func mostrar(jugadores: Array, mi_id: int) -> void:
	_jugadores = jugadores
	_mi_id = mi_id
	_redibujar()


func marcar_turno(jugador_id: int) -> void:
	_turno_id = jugador_id
	_redibujar()


func _redibujar() -> void:
	Estilo.vaciar(_filas)
	_texto_turno.text = "Esperando el primer turno..."
	for datos: Dictionary in _jugadores:
		var es_turno: bool = datos.id == _turno_id
		var fila_panel := PanelContainer.new()
		var fondo := Estilo.PRIMARIO_SUAVE if es_turno else Color.TRANSPARENT
		fila_panel.add_theme_stylebox_override("panel", Estilo.caja(fondo, 10, Color.TRANSPARENT, 8))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		fila_panel.add_child(fila)

		fila.add_child(AvatarIcono.new(Estilo.color_de(datos.color), datos.avatar, 34))
		var textos := VBoxContainer.new()
		textos.add_theme_constant_override("separation", 0)
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nombre: String = datos.nombre + (" (tú)" if datos.id == _mi_id else "")
		textos.add_child(Estilo.etiqueta(nombre, 15, Estilo.TEXTO, true))
		textos.add_child(Estilo.etiqueta("%s · %d fichas en meta" % [Estilo.NOMBRES[datos.color], datos.fichas_en_meta], 12, Estilo.TEXTO_SUAVE))
		fila.add_child(textos)
		if es_turno:
			fila.add_child(Estilo.pildora("Turno", Estilo.PRIMARIO, Color.WHITE))
			_texto_turno.text = "Turno de %s · %d fichas en meta" % [datos.nombre, datos.fichas_en_meta]
		_filas.add_child(fila_panel)
