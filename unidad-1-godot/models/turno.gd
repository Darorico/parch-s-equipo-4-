class_name Turno
extends RefCounted
## Control de turnos: orden horario fijo, jugador en turno, fase del turno y tiros seguidos (regla del 6).

enum Fase { LANZAR, ELEGIR_FICHA }

var orden: Array[int] = []
var indice := 0
var tiros_seguidos := 0
var fase: Fase = Fase.LANZAR


func iniciar(p_orden: Array[int], primero: int) -> void:
	orden = p_orden
	indice = maxi(orden.find(primero), 0)
	tiros_seguidos = 0
	fase = Fase.LANZAR


func jugador_actual() -> int:
	return orden[indice] if not orden.is_empty() else 0


## Pasa el turno al siguiente jugador en sentido horario.
func siguiente() -> int:
	if orden.is_empty():
		return 0
	indice = (indice + 1) % orden.size()
	tiros_seguidos = 0
	fase = Fase.LANZAR
	return jugador_actual()


## El mismo jugador vuelve a tirar (CU13 Repetir Tiro).
func repetir() -> void:
	fase = Fase.LANZAR


## Saca a un jugador del orden (abandono). Devuelve true si era su turno.
func quitar(jugador_id: int) -> bool:
	var posicion := orden.find(jugador_id)
	if posicion == -1:
		return false
	var era_su_turno := posicion == indice
	orden.remove_at(posicion)
	if orden.is_empty():
		indice = 0
	elif posicion < indice:
		indice -= 1
	elif era_su_turno:
		indice %= orden.size()
		tiros_seguidos = 0
		fase = Fase.LANZAR
	return era_su_turno


## Usado por las réplicas del Modelo en los clientes.
func fijar_actual(jugador_id: int) -> void:
	var posicion := orden.find(jugador_id)
	if posicion != -1:
		indice = posicion
	fase = Fase.LANZAR
