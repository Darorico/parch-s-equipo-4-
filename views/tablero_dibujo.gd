@tool
class_name TableroDibujo
extends Control
## Tablero de parchís dibujado a crayón sobre la hoja (19×19 casillas) y sus fichas.
##
## Distribución (como el dibujo de referencia): rojo arriba-izquierda, verde arriba-derecha,
## amarillo abajo-derecha y azul abajo-izquierda. Las fichas avanzan en sentido ANTIHORARIO.
##
## Rendimiento: el tablero se dibuja una sola vez en VARIANTES versiones (canvas items hijos) y en cada
## cuadro de la animación solo se muestra una, así «tiembla» en stop-motion sin redibujar todo. Las
## fichas sí se dibujan en cada cuadro y avanzan casilla por casilla dando saltitos.
##
## En el editor (views/escenas/vista_tablero.tscn) se dibuja con fichas de ejemplo y sus propiedades
## se pueden ajustar en el Inspector (sección «Dibujo del tablero»).

signal ficha_clicada(ficha_id: int)

const N := 19
const CASILLAS := 68
const VARIANTES := 3
## Esquina superior izquierda de la casa (8×8) de cada color.
const CASAS := {
	"rojo": Vector2i(0, 0), "verde": Vector2i(11, 0), "amarillo": Vector2i(11, 11), "azul": Vector2i(0, 11),
}
## Salida de cada color (índice en el recorrido; coincide con el subsistema de reglas).
const SALIDAS := {"rojo": 4, "azul": 21, "amarillo": 38, "verde": 55}
## Casillas seguras grises (además de las salidas).
const SEGUROS := [11, 16, 28, 33, 45, 50, 62, 67]
## Pasillo de meta de cada color: primera casilla y dirección hacia el centro.
const PASILLOS := {
	"rojo": [Vector2i(9, 1), Vector2i(0, 1)],
	"verde": [Vector2i(17, 9), Vector2i(-1, 0)],
	"amarillo": [Vector2i(9, 17), Vector2i(0, -1)],
	"azul": [Vector2i(1, 9), Vector2i(1, 0)],
}
const DESPLAZAMIENTOS := [Vector2(-0.2, -0.2), Vector2(0.2, 0.2), Vector2(0.2, -0.2), Vector2(-0.2, 0.2)]

## Las 68 casillas del recorrido en orden de avance (sentido antihorario).
static var RECORRIDO: Array[Vector2i] = _construir_recorrido()

@export_group("Dibujo del tablero")
## Grosor de las líneas de lápiz.
@export_range(0.5, 6.0, 0.1) var grosor_lapiz := 2.4:
	set(valor):
		grosor_lapiz = valor
		_invalidar()
## Cuánto ondulan las líneas (0 = rectas).
@export_range(0.0, 5.0, 0.1) var temblor := 1.4:
	set(valor):
		temblor = valor
		_invalidar()
## Distancia entre las rayas del crayón en casas y pasillos (más chica = color más lleno).
@export_range(2.0, 12.0, 0.5) var separacion_crayon := 4.5:
	set(valor):
		separacion_crayon = valor
		_invalidar()
## Tamaño de las fichas en el recorrido, en fracción de casilla.
@export_range(0.2, 0.5, 0.01) var radio_ficha := 0.42:
	set(valor):
		radio_ficha = valor
		queue_redraw()
## Solo en el editor: dibuja fichas de ejemplo para ver cómo queda.
@export var fichas_de_ejemplo := true:
	set(valor):
		fichas_de_ejemplo = valor
		queue_redraw()
@export_group("")

var _jugadores: Array = []  # [{id, color, fichas: [casillas]}]
var _visual := {}           # Vector2i(jugador_id, indice) -> casilla mostrada durante una animación
var _elevadas := {}         # Vector2i(jugador_id, indice) -> true mientras la ficha está en el aire
var _animacion := {}        # Vector2i(jugador_id, indice) -> número de animación vigente
var _activo_id := 0
var _movibles: Array = []
var _seleccionada := 0
var _celda := 0.0
var _origen := Vector2.ZERO
var _zonas_clic: Array = []  # [{centro, radio, ficha}]
var _capas: Array[RID] = []
var _tamano_capas := Vector2.ZERO


func _init() -> void:
	custom_minimum_size = Vector2(420, 420)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_to_group(Garabato.GRUPO_VIVO)


func _notification(que: int) -> void:
	if que == NOTIFICATION_PREDELETE:
		_liberar_capas()


func mostrar_jugadores(jugadores: Array) -> void:
	_jugadores = jugadores.duplicate(true)
	_visual.clear()
	_elevadas.clear()
	queue_redraw()


## Actualiza las posiciones animando cada ficha que cambió. Devuelve cuánto dura la animación.
func mostrar_posiciones(posiciones: Dictionary) -> float:
	var duracion := 0.0
	for jugador: Dictionary in _jugadores:
		if not posiciones.has(jugador.id):
			continue
		var nuevas: Array = posiciones[jugador.id]
		for k in mini(nuevas.size(), jugador.fichas.size()):
			var antes: int = jugador.fichas[k]
			var despues: int = nuevas[k]
			if antes != despues:
				jugador.fichas[k] = despues
				duracion = maxf(duracion, _animar_ficha(Vector2i(jugador.id, k), antes, despues))
	queue_redraw()
	return duracion


## Resalta las fichas que el jugador local puede mover (vacío para quitar el resaltado).
func resaltar(jugador_id: int, movibles: Array, seleccionada := 0) -> void:
	_activo_id = jugador_id
	_movibles = movibles.duplicate()
	_seleccionada = seleccionada
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var clic := event as InputEventMouseButton
	if clic == null or not clic.pressed or clic.button_index != MOUSE_BUTTON_LEFT:
		return
	for zona: Dictionary in _zonas_clic:
		if clic.position.distance_to(zona.centro) <= zona.radio * 1.3:
			ficha_clicada.emit(zona.ficha)
			accept_event()
			return


# ---------------------------------------------------------------------------
# Animación de fichas (stop-motion)
# ---------------------------------------------------------------------------

func _animar_ficha(clave: Vector2i, antes: int, despues: int) -> float:
	_animacion[clave] = _animacion.get(clave, 0) + 1
	if antes >= 0 and despues >= 0:
		var pasos := posmod(despues - antes, CASILLAS)
		_recorrer(clave, antes, pasos, _animacion[clave])
		return float(pasos + 1) / Animaciones.CUADROS_POR_SEGUNDO
	_saltar(clave, despues < 0, _animacion[clave])
	return 2.0 / Animaciones.CUADROS_POR_SEGUNDO


## La ficha avanza una casilla por cuadro, en el aire, y aterriza al final.
func _recorrer(clave: Vector2i, desde: int, pasos: int, animacion: int) -> void:
	for i in range(1, pasos + 1):
		if _animacion.get(clave) != animacion:
			return
		_visual[clave] = posmod(desde + i, CASILLAS)
		_elevadas[clave] = true
		queue_redraw()
		Sonidos.ficha_paso()
		await Animaciones.esperar_cuadros(1)
	if _animacion.get(clave) == animacion:
		_visual.erase(clave)
		_elevadas.erase(clave)
		queue_redraw()


## Salir de casa o volver a ella: un solo salto.
func _saltar(clave: Vector2i, regresa_a_casa: bool, animacion: int) -> void:
	_elevadas[clave] = true
	queue_redraw()
	if regresa_a_casa:
		Sonidos.ficha_capturada()
	else:
		Sonidos.ficha_sale()
	await Animaciones.esperar_cuadros(1)
	if _animacion.get(clave) == animacion:
		_elevadas.erase(clave)
		queue_redraw()


# ---------------------------------------------------------------------------
# Dibujo
# ---------------------------------------------------------------------------

func _draw() -> void:
	_celda = floorf(minf(size.x, size.y) / N)
	_origen = ((size - Vector2.ONE * _celda * N) / 2.0).floor()
	_actualizar_capas()
	var viva := not Engine.is_editor_hint() and Animaciones.linea_viva
	var variante := Garabato.cuadro % VARIANTES if viva else 0
	for i in _capas.size():
		RenderingServer.canvas_item_set_visible(_capas[i], i == variante)
	_dibujar_fichas()


func _actualizar_capas() -> void:
	if _tamano_capas == size and not _capas.is_empty():
		return
	_liberar_capas()
	_tamano_capas = size
	for variante in VARIANTES:
		var capa := RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(capa, get_canvas_item())
		RenderingServer.canvas_item_set_draw_behind_parent(capa, true)
		_dibujar_tablero(capa, variante * 1000)
		_capas.append(capa)


## Fuerza a redibujar el tablero completo (al cambiar una propiedad en el Inspector).
func _invalidar() -> void:
	_tamano_capas = Vector2.ZERO
	queue_redraw()


func _liberar_capas() -> void:
	for capa in _capas:
		RenderingServer.free_rid(capa)
	_capas.clear()


func _dibujar_tablero(ci: RID, s: int) -> void:
	for color: String in CASAS:
		var rect := _rect(CASAS[color], Vector2i(8, 8))
		Garabato.rellenar_rect(ci, rect.grow(-3), Estilo.color_de(color), s + _hash(color), separacion_crayon)
		Garabato.rect(ci, rect, Garabato.LAPIZ, grosor_lapiz, s + _hash(color) + 1, temblor)
		for k in 4:
			Garabato.circulo(ci, _hueco_casa(color, k), _celda * 0.78, Garabato.LAPIZ, grosor_lapiz * 0.9, s + _hash(color) + 10 + k, temblor * 0.7)

	for i in RECORRIDO.size():
		if i in SEGUROS:
			_casilla_especial(ci, RECORRIDO[i], Estilo.GRIS_SEGURO, s + i)
		else:
			Garabato.rect(ci, _rect(RECORRIDO[i]), Color(Garabato.LAPIZ, 0.85), grosor_lapiz * 0.62, s + i * 7, temblor * 0.65)
	for color: String in SALIDAS:
		_casilla_especial(ci, RECORRIDO[SALIDAS[color]], Estilo.color_de(color), s + 300 + SALIDAS[color])
	for color: String in PASILLOS:
		var inicio: Vector2i = PASILLOS[color][0]
		var direccion: Vector2i = PASILLOS[color][1]
		for k in 7:
			var rect := _rect(inicio + direccion * k)
			Garabato.rellenar_rect(ci, rect.grow(-2), Estilo.color_de(color), s + _hash(color) + 50 + k, separacion_crayon * 0.78)
			Garabato.rect(ci, rect, Color(Garabato.LAPIZ, 0.85), grosor_lapiz * 0.62, s + _hash(color) + 70 + k, temblor * 0.65)

	var a := _origen + Vector2(8, 8) * _celda
	var b := _origen + Vector2(11, 11) * _celda
	var centro := (a + b) / 2.0
	var triangulos := {
		"rojo": [a, Vector2(b.x, a.y)], "verde": [Vector2(b.x, a.y), b],
		"amarillo": [b, Vector2(a.x, b.y)], "azul": [Vector2(a.x, b.y), a],
	}
	for color: String in triangulos:
		var triangulo := PackedVector2Array([triangulos[color][0], triangulos[color][1], centro])
		Garabato.rellenar(ci, triangulo, Estilo.color_de(color), s + _hash(color) + 90, separacion_crayon * 0.78)
		Garabato.contorno(ci, triangulo, Garabato.LAPIZ, grosor_lapiz * 0.83, s + _hash(color) + 91, temblor * 0.7)
	Garabato.rect(ci, Rect2(_origen, Vector2.ONE * _celda * N), Garabato.LAPIZ, grosor_lapiz * 1.15, s + 999, temblor * 1.15)


## Casilla segura o de salida: coloreada a crayón con un circulito al centro.
func _casilla_especial(ci: RID, celda: Vector2i, color: Color, semilla: int) -> void:
	var rect := _rect(celda)
	Garabato.rellenar_rect(ci, rect.grow(-2), color, semilla, separacion_crayon * 0.67)
	RenderingServer.canvas_item_add_circle(ci, rect.get_center(), _celda * 0.27, Estilo.PAPEL)
	Garabato.circulo(ci, rect.get_center(), _celda * 0.27, Garabato.LAPIZ, grosor_lapiz * 0.67, semilla + 1, temblor * 0.35)
	Garabato.rect(ci, rect, Garabato.LAPIZ, grosor_lapiz * 0.67, semilla + 2, temblor * 0.65)


func _dibujar_fichas() -> void:
	_zonas_clic.clear()
	var por_casilla := {}
	var jugadores := _jugadores
	if Engine.is_editor_hint() and jugadores.is_empty() and fichas_de_ejemplo:
		jugadores = _jugadores_de_ejemplo()
	for jugador: Dictionary in jugadores:
		var fichas: Array = jugador.fichas
		for k in fichas.size():
			var casilla: int = _visual.get(Vector2i(jugador.id, k), fichas[k])
			if casilla < 0:
				_dibujar_ficha(jugador, k, _hueco_casa(jugador.color, k), _celda * 0.6)
			else:
				por_casilla.get_or_add(casilla, []).append([jugador, k])
	for casilla: int in por_casilla:
		var grupo: Array = por_casilla[casilla]
		var centro := _rect(RECORRIDO[casilla]).get_center()
		for n in grupo.size():
			if grupo.size() == 1:
				_dibujar_ficha(grupo[n][0], grupo[n][1], centro, _celda * radio_ficha)
			else:
				_dibujar_ficha(grupo[n][0], grupo[n][1], centro + DESPLAZAMIENTOS[n % 4] * _celda, _celda * radio_ficha * 0.72)


func _dibujar_ficha(jugador: Dictionary, indice: int, centro: Vector2, radio: float) -> void:
	var ci := get_canvas_item()
	var numero := indice + 1
	var clave := Vector2i(jugador.id, indice)
	var semilla := Garabato.semilla_de(clave) + Garabato.cuadro % 3
	if _elevadas.has(clave):
		# En el aire: sombra en el piso y la ficha un poco más arriba.
		draw_circle(centro + Vector2(0, radio * 0.25), radio * 0.8, Color(0, 0, 0, 0.15))
		centro.y -= _celda * 0.35
	var es_movible: bool = jugador.id == _activo_id and numero in _movibles
	if es_movible:
		Garabato.rellenar_circulo(get_canvas_item(), centro, radio + _celda * 0.22, Color(Estilo.RESALTADOR, 0.8), semilla + 20)
		_zonas_clic.append({"centro": centro, "radio": radio, "ficha": numero})
	if es_movible and numero == _seleccionada:
		Garabato.circulo(ci, centro, radio + _celda * 0.22, Estilo.PRIMARIO, 3.0, semilla + 21, 1.0)
	# Halo de papel para que la ficha resalte aunque esté sobre su casa del mismo color.
	RenderingServer.canvas_item_add_circle(ci, centro, radio + maxf(2.5, radio * 0.14), Estilo.PAPEL)
	Garabato.disco(ci, centro, radio, Estilo.color_de(jugador.color).darkened(0.12), semilla)
	var tamano := maxi(int(radio * 1.15), 9)
	var posicion := centro + Vector2(-radio, tamano * 0.34)
	draw_string_outline(Estilo.negrita(), posicion, str(numero), HORIZONTAL_ALIGNMENT_CENTER, radio * 2.0, tamano, 4, Garabato.LAPIZ)
	draw_string(Estilo.negrita(), posicion, str(numero), HORIZONTAL_ALIGNMENT_CENTER, radio * 2.0, tamano, Estilo.PAPEL)


func _hueco_casa(color: String, k: int) -> Vector2:
	var centro := _origen + (Vector2(CASAS[color]) + Vector2(4, 4)) * _celda
	var direcciones := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	return centro + direcciones[k] * _celda * 1.9


func _rect(celda: Vector2i, tamano := Vector2i.ONE) -> Rect2:
	return Rect2(_origen + Vector2(celda) * _celda, Vector2(tamano) * _celda)


## Fichas que se ven en el editor para orientarse (no se usan en el juego).
static func _jugadores_de_ejemplo() -> Array:
	return [
		{"id": 1, "color": "rojo", "fichas": [4, 9, -1, -1]},
		{"id": 2, "color": "verde", "fichas": [55, -1, -1, -1]},
		{"id": 3, "color": "amarillo", "fichas": [-1, -1, -1, -1]},
		{"id": 4, "color": "azul", "fichas": [21, 30, 30, -1]},
	]


static func _hash(texto: String) -> int:
	return absi(hash(texto)) % 10000


## Recorrido antihorario. Cada brazo aporta 17 casillas: la columna (o fila) por la que se baja hacia
## el centro, el extremo exterior y la columna (o fila) por la que se sube. La salida de cada color es
## la 5.ª casilla de su brazo y la entrada a su pasillo es el extremo exterior de ese mismo brazo.
static func _construir_recorrido() -> Array[Vector2i]:
	var r: Array[Vector2i] = []
	# Brazo superior (rojo): columna izquierda hacia el centro.
	for y in range(0, 8):
		r.append(Vector2i(8, y))
	# Brazo izquierdo (azul): fila superior hacia afuera, extremo y fila inferior hacia el centro.
	for x in range(7, -1, -1):
		r.append(Vector2i(x, 8))
	r.append(Vector2i(0, 9))
	for x in range(0, 8):
		r.append(Vector2i(x, 10))
	# Brazo inferior (amarillo): columna izquierda hacia afuera, extremo y columna derecha hacia el centro.
	for y in range(11, 19):
		r.append(Vector2i(8, y))
	r.append(Vector2i(9, 18))
	for y in range(18, 10, -1):
		r.append(Vector2i(10, y))
	# Brazo derecho (verde): fila inferior hacia afuera, extremo y fila superior hacia el centro.
	for x in range(11, 19):
		r.append(Vector2i(x, 10))
	r.append(Vector2i(18, 9))
	for x in range(18, 10, -1):
		r.append(Vector2i(x, 8))
	# Brazo superior (rojo): columna derecha hacia afuera y extremo (entrada al pasillo rojo).
	for y in range(7, -1, -1):
		r.append(Vector2i(10, y))
	r.append(Vector2i(9, 0))
	return r
