extends Node
## GESTOR DE SONIDOS (autoload «Sonidos»). Estructura lista para los efectos de sonido.
##
## Cómo agregar un sonido: copia el archivo a `res://assets/sonidos/` con el nombre del efecto
## (por ejemplo `clic.ogg`, `ficha_paso.wav`). No hay que tocar código; si el archivo no existe,
## la función correspondiente no hace nada. Formatos: .ogg, .wav o .mp3.
##
## Efectos que el juego ya dispara:
##   clic             cualquier botón (se conecta solo a todos los botones que aparezcan)
##   pantalla         cambio de pantalla
##   dado             al lanzar el dado
##   ficha_paso       cada casilla que avanza una ficha
##   ficha_sale       una ficha sale de su casa
##   ficha_capturada  una ficha regresa a su casa
##   turno            empieza tu turno

const CARPETA := "res://assets/sonidos/"
const EXTENSIONES := ["ogg", "wav", "mp3"]
const CANALES := 6

## Volumen general en decibeles y silencio global.
var volumen_db := 0.0
var silenciado := false

var _reproductores: Array[AudioStreamPlayer] = []
var _cache := {}  # nombre -> AudioStream (o null si no existe el archivo)


func _ready() -> void:
	for i in CANALES:
		var reproductor := AudioStreamPlayer.new()
		add_child(reproductor)
		_reproductores.append(reproductor)
	get_tree().node_added.connect(_on_nodo_agregado)


# --- Funciones por evento (las llaman las vistas) ---

func clic() -> void:
	reproducir(&"clic")


func cambio_pantalla() -> void:
	reproducir(&"pantalla")


func dado() -> void:
	reproducir(&"dado")


func ficha_paso() -> void:
	reproducir(&"ficha_paso", randf_range(0.92, 1.08))


func ficha_sale() -> void:
	reproducir(&"ficha_sale")


func ficha_capturada() -> void:
	reproducir(&"ficha_capturada")


func turno_propio() -> void:
	reproducir(&"turno")


# --- Motor ---

## Reproduce el efecto `nombre` si existe su archivo. `tono` permite variar un poco cada repetición.
func reproducir(nombre: StringName, tono := 1.0) -> void:
	if silenciado:
		return
	var sonido := _cargar(nombre)
	if sonido == null:
		return
	var reproductor := _reproductor_libre()
	reproductor.stream = sonido
	reproductor.volume_db = volumen_db
	reproductor.pitch_scale = tono
	reproductor.play()


func _cargar(nombre: StringName) -> AudioStream:
	if _cache.has(nombre):
		return _cache[nombre]
	var sonido: AudioStream = null
	for extension in EXTENSIONES:
		var ruta := "%s%s.%s" % [CARPETA, nombre, extension]
		if ResourceLoader.exists(ruta):
			sonido = load(ruta)
			break
	_cache[nombre] = sonido
	return sonido


func _reproductor_libre() -> AudioStreamPlayer:
	for reproductor in _reproductores:
		if not reproductor.playing:
			return reproductor
	return _reproductores[0]


func _on_nodo_agregado(nodo: Node) -> void:
	if nodo is BaseButton:
		(nodo as BaseButton).pressed.connect(clic)
