class_name ControladorTurno
extends RefCounted
## CONTROLADOR del caso de uso «Ejercer turno del juego» (CU12).
## Recibe las acciones del usuario desde la Vista y las convierte en peticiones al Modelo. Como el
## Modelo autoritativo vive en el servidor, la petición viaja por la red; si este equipo es el
## servidor, Red se la entrega directamente a su Partida.
##
## El Controlador no cambia la interfaz: la Vista se actualiza sola cuando el Modelo emite sus señales.


## CU04 Lanzar Dado.
func procesar_lanzamiento_dado() -> void:
	Red.solicitar(&"lanzar_dado")


## CU05 Liberar Ficha.
func liberar_ficha() -> void:
	Red.solicitar(&"liberar_ficha")


## CU06 Mover Ficha.
func mover_ficha(ficha_id: int) -> void:
	Red.solicitar(&"mover_ficha", [ficha_id])
