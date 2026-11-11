class_name Dado
extends RefCounted
## Dado virtual del Modelo. El valor lo genera el subsistema de reglas (a través de la fachada).

const CARAS := 6

var valor_actual := 0


func generar_valor(fachada: FachadaReglas) -> int:
	valor_actual = fachada.generar_valor()
	return valor_actual
