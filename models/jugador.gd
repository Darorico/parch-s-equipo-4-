class_name Jugador
extends RefCounted
## Jugador registrado en la partida (CU01): nombre, color, avatar y sus cuatro fichas.

## Colores en sentido horario sobre el tablero: rojo (arriba-izq), verde (arriba-der),
## amarillo (abajo-der) y azul (abajo-izq). Es el orden de los turnos (horario, como pide el PDF);
## las fichas, en cambio, avanzan en sentido antihorario.
const COLORES: Array[String] = ["rojo", "verde", "amarillo", "azul"]
const FICHAS_POR_JUGADOR := 4

var id: int
var nombre: String
var color: String
var avatar: int
var listo := false
var fichas: Array[Ficha] = []
var fichas_en_meta := 0


func _init(p_id: int, p_nombre: String, p_color: String, p_avatar: int) -> void:
	id = p_id
	nombre = p_nombre
	color = p_color
	avatar = p_avatar
	for i in FICHAS_POR_JUGADOR:
		fichas.append(Ficha.new(i + 1, color))


func actualizar_casillas(casillas: Array) -> void:
	for i in mini(casillas.size(), fichas.size()):
		fichas[i].casilla = casillas[i]


## Datos planos que viajan en las señales y por la red.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"nombre": nombre,
		"color": color,
		"avatar": avatar,
		"listo": listo,
		"fichas": fichas.map(func(f: Ficha) -> int: return f.casilla),
		"fichas_en_meta": fichas_en_meta,
	}


static func desde_dict(datos: Dictionary) -> Jugador:
	var jugador := Jugador.new(datos.id, datos.nombre, datos.color, datos.avatar)
	jugador.listo = datos.listo
	jugador.fichas_en_meta = datos.fichas_en_meta
	jugador.actualizar_casillas(datos.fichas)
	return jugador
