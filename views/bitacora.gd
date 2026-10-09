class_name Bitacora
extends PanelContainer
## Caja amarilla con los mensajes del turno (resultados que devuelve el subsistema de reglas).

const MAXIMO := 6

var _lineas := VBoxContainer.new()


func _init() -> void:
	add_theme_stylebox_override("panel", Estilo.caja(Estilo.AVISO, 14, Estilo.AVISO_BORDE, 14))
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	columna.add_child(Estilo.etiqueta("Bitácora del turno", 15, Estilo.TEXTO, true))
	_lineas.add_theme_constant_override("separation", 4)
	columna.add_child(_lineas)
	add_child(columna)


func agregar(texto: String, color := Estilo.TEXTO) -> void:
	var linea := Estilo.parrafo("• " + texto, 13, color)
	_lineas.add_child(linea)
	_lineas.move_child(linea, 0)
	while _lineas.get_child_count() > MAXIMO:
		var vieja := _lineas.get_child(_lineas.get_child_count() - 1)
		_lineas.remove_child(vieja)
		vieja.queue_free()
