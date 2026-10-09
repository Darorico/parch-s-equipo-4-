extends Node
## GESTOR DE ANIMACIONES (autoload «Animaciones»). Todas las animaciones van en estilo stop-motion
## (pocos cuadros por segundo, a saltos), como un dibujo hecho a mano en el cuaderno.
##
##   - Línea viva: ~8 veces por segundo avanza Garabato.cuadro y redibuja los nodos del grupo
##     «garabato_vivo», así los trazos tiemblan como animación cuadro por cuadro.
##   - transicion_pantalla(): una hoja de papel tapa la pantalla y se retira a saltos.
##   - esperar_cuadros(n): pausa medida en cuadros, para animar a ese ritmo (fichas, dado).
##
## Para agregar una animación nueva: escribe una función aquí que avance a saltos con
## `await esperar_cuadros(1)` entre cada cambio.

signal cuadro_nuevo(numero: int)

const CUADROS_POR_SEGUNDO := 8
const GRUPO_VIVO := &"garabato_vivo"
const PASOS_TRANSICION := 6

## Desactívalo si en algún equipo la interfaz se siente pesada.
var linea_viva := true

var _acumulado := 0.0
var _capa: CanvasLayer
var _hoja: Control
var _transicion := 0


func _process(delta: float) -> void:
	_acumulado += delta
	var duracion := 1.0 / CUADROS_POR_SEGUNDO
	if _acumulado < duracion:
		return
	_acumulado = fmod(_acumulado, duracion)
	Garabato.cuadro += 1
	cuadro_nuevo.emit(Garabato.cuadro)
	if linea_viva:
		get_tree().call_group(GRUPO_VIVO, &"queue_redraw")


## Espera `n` cuadros de la animación stop-motion.
func esperar_cuadros(n := 1) -> void:
	await get_tree().create_timer(float(n) / CUADROS_POR_SEGUNDO).timeout


## Transición de pantalla: la hoja empieza tapando todo y se retira hacia la derecha a saltos,
## con un leve bamboleo en cada cuadro.
func transicion_pantalla() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_transicion += 1
	var esta_transicion := _transicion
	if _capa == null:
		_crear_hoja()
	var tamano := get_viewport().get_visible_rect().size
	_hoja.size = tamano
	_hoja.visible = true
	Sonidos.cambio_pantalla()
	for paso in PASOS_TRANSICION + 1:
		if esta_transicion != _transicion:
			return
		_hoja.position = Vector2(tamano.x * paso / PASOS_TRANSICION, randf_range(-3.0, 3.0))
		_hoja.rotation = randf_range(-0.012, 0.012)
		await esperar_cuadros(1)
	if esta_transicion == _transicion:
		_hoja.visible = false


func _crear_hoja() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 100
	add_child(_capa)
	_hoja = _BordeHoja.new()
	_hoja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var papel := FondoPapel.new()
	papel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hoja.add_child(papel)
	_capa.add_child(_hoja)
	_hoja.visible = false


## Hoja de la transición con su borde izquierdo rasgado y repasado con lápiz.
class _BordeHoja extends Control:
	func _draw() -> void:
		var ci := get_canvas_item()
		var rng := RandomNumberGenerator.new()
		rng.seed = Garabato.cuadro
		var puntos := PackedVector2Array()
		var y := 0.0
		while y <= size.y:
			puntos.append(Vector2(rng.randf_range(-10.0, 0.0), y))
			y += rng.randf_range(8.0, 18.0)
		puntos.append(Vector2(0, size.y))
		var poligono := puntos.duplicate()
		poligono.append(Vector2(20, size.y))
		poligono.append(Vector2(20, 0))
		RenderingServer.canvas_item_add_polygon(ci, poligono, PackedColorArray([Color("#fbfaf6")]))
		RenderingServer.canvas_item_add_polyline(ci, puntos, PackedColorArray([Garabato.LAPIZ]), 2.0, true)

	func _process(_delta: float) -> void:
		if visible:
			queue_redraw()
