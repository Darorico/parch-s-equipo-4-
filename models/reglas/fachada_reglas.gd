class_name FachadaReglas
extends RefCounted
## PATRÓN FACHADA: es el único punto de acceso del Modelo al subsistema de reglas de negocio
## (las entidades Tablero, Casilla, Ficha y Dado).
##
## El motor de reglas real todavía no existe, así que detrás de esta fachada se conecta un objeto
## Mock (ReglasMock) que simula las reglas básicas del turno. Cuando exista el motor real, solo se
## cambia el subsistema que recibe el constructor; el Modelo no se entera.

## Subsistema de reglas: hoy ReglasMock, en el futuro el motor real con la misma interfaz.
var _subsistema


func _init(subsistema = null) -> void:
	_subsistema = subsistema if subsistema != null else ReglasMock.new()


## Coloca las fichas de todos los jugadores en su casa. `colores` es jugador_id -> color.
func iniciar_partida(colores: Dictionary) -> void:
	_subsistema.preparar_tablero(colores)


## CU04 Lanzar Dado: número aleatorio del 1 al 6.
func generar_valor() -> int:
	return _subsistema.generar_valor()


## Qué puede hacer el jugador con ese valor: fichas que puede mover y si puede sacar una de casa.
func opciones(jugador_id: int, valor: int) -> Dictionary:
	return {
		"movibles": _subsistema.fichas_movibles(jugador_id, valor),
		"puede_liberar": _subsistema.puede_liberar(jugador_id, valor),
	}


## CU05 Liberar Ficha. Devuelve {ok, ficha_id, mensaje, posiciones}.
func liberar_ficha(jugador_id: int, valor: int) -> Dictionary:
	return _subsistema.posicionar_en_salida(jugador_id, valor)


## CU06 Mover Ficha (incluye CU07 Capturar Ficha). Devuelve {ok, ficha_id, mensaje, posiciones}.
func mover_ficha(jugador_id: int, ficha_id: int, valor: int) -> Dictionary:
	return _subsistema.actualizar_posicion(jugador_id, ficha_id, valor)


## Valida el fin del turno. Devuelve true si el turno termina y false si el jugador vuelve a tirar (CU13).
func validar_fin_turno(jugador_id: int, valor: int, tiros_seguidos: int) -> bool:
	return not _subsistema.repite_turno(jugador_id, valor, tiros_seguidos)


## CU10 Gestionar Abandono: las fichas del jugador desaparecen del tablero.
func retirar_jugador(jugador_id: int) -> void:
	_subsistema.retirar_fichas(jugador_id)


func posiciones() -> Dictionary:
	return _subsistema.posiciones()
