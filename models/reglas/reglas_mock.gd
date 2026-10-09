class_name ReglasMock
extends RefCounted
## OBJETO MOCK del subsistema de reglas. Sustituye al motor real (Tablero, Casilla, Ficha y Dado)
## y simula solo lo necesario para ejercer un turno:
##   - generar_valor(): número aleatorio del 1 al 6.
##   - Con un 5: «Sacar ficha de la casa» (posicionar_en_salida), con mensaje de éxito.
##   - Con cualquier número: «Ficha movida N casillas» (actualizar_posicion).
##   - Captura simple: si cae sobre una ficha rival fuera de una salida, la manda a su casa.
##   - Fin de turno: con un 6 se vuelve a tirar (máximo 3 tiros seguidos); si no, el turno pasa.
## No simula barreras, el pasillo de meta ni la victoria por meta (eso es del motor real).

const CASILLAS_RECORRIDO := 68
const EN_CASA := -1
const VALOR_PARA_SALIR := 5
const VALOR_REPETIR := 6
const MAX_TIROS_SEGUIDOS := 3
const REPETIR_CON_SEIS := true
## Casilla de salida de cada color (índice en el recorrido de 68 casillas).
const SALIDAS := {"verde": 4, "amarillo": 21, "azul": 38, "rojo": 55}

var _rng := RandomNumberGenerator.new()
## Valores forzados del dado (solo para grabar demos reproducibles: `-- --dados=5,3,6,2`).
var _secuencia_dados: Array[int] = []
var _colores := {}   # jugador_id -> color
var _casillas := {}  # jugador_id -> [casilla de la ficha 1..4]


func _init(secuencia_dados: Array[int] = []) -> void:
	_rng.randomize()
	_secuencia_dados = secuencia_dados.duplicate()


func preparar_tablero(colores: Dictionary) -> void:
	_colores = colores.duplicate()
	_casillas.clear()
	for jugador_id: int in _colores:
		_casillas[jugador_id] = [EN_CASA, EN_CASA, EN_CASA, EN_CASA]


func generar_valor() -> int:
	if not _secuencia_dados.is_empty():
		return clampi(_secuencia_dados.pop_front(), 1, 6)
	return _rng.randi_range(1, 6)


func puede_liberar(jugador_id: int, valor: int) -> bool:
	return valor == VALOR_PARA_SALIR and EN_CASA in _casillas.get(jugador_id, [])


## Ids (1..4) de las fichas que están fuera de casa.
func fichas_movibles(jugador_id: int, _valor: int) -> Array:
	var movibles := []
	var casillas: Array = _casillas.get(jugador_id, [])
	for i in casillas.size():
		if casillas[i] != EN_CASA:
			movibles.append(i + 1)
	return movibles


## Simula «Sacar ficha de la casa»: la primera ficha en casa pasa a la salida de su color.
func posicionar_en_salida(jugador_id: int, valor: int) -> Dictionary:
	if not puede_liberar(jugador_id, valor):
		return _fallo("Solo con un 5 se puede sacar una ficha de casa.")
	var indice: int = _casillas[jugador_id].find(EN_CASA)
	_casillas[jugador_id][indice] = SALIDAS[_colores[jugador_id]]
	return _exito(indice + 1, "¡Éxito! Sacó la ficha %d de la casa a su salida." % (indice + 1))


## Simula «Ficha movida N casillas» sobre el recorrido circular.
func actualizar_posicion(jugador_id: int, ficha_id: int, valor: int) -> Dictionary:
	var indice := ficha_id - 1
	var casillas: Array = _casillas.get(jugador_id, [])
	if indice < 0 or indice >= casillas.size() or casillas[indice] == EN_CASA:
		return _fallo("Esa ficha no se puede mover.")
	var destino: int = (casillas[indice] + valor) % CASILLAS_RECORRIDO
	casillas[indice] = destino
	var texto := "Ficha %d movida %d casillas." % [ficha_id, valor]
	var capturada := enviar_ficha_a_base(jugador_id, destino)
	if capturada != "":
		texto += " ¡Capturó una ficha %s, que regresa a su casa!" % capturada
	return _exito(ficha_id, texto)


## Simula CU07 Capturar Ficha. Devuelve el color capturado o "" si no hubo captura.
func enviar_ficha_a_base(jugador_id: int, casilla: int) -> String:
	if casilla in SALIDAS.values():
		return ""  # Las salidas son casillas seguras.
	for otro: int in _casillas:
		if otro == jugador_id:
			continue
		var indice: int = _casillas[otro].find(casilla)
		if indice != -1:
			_casillas[otro][indice] = EN_CASA
			return _colores[otro]
	return ""


## CU08 Bloquear Camino: no se simula en este Mock.
func establecer_barrera(_jugador_id: int, _casilla: int) -> bool:
	return false


## Con un 6 se repite el tiro, hasta 3 tiros seguidos.
func repite_turno(_jugador_id: int, valor: int, tiros_seguidos: int) -> bool:
	return REPETIR_CON_SEIS and valor == VALOR_REPETIR and tiros_seguidos < MAX_TIROS_SEGUIDOS


func retirar_fichas(jugador_id: int) -> void:
	_casillas.erase(jugador_id)
	_colores.erase(jugador_id)


func posiciones() -> Dictionary:
	return _casillas.duplicate(true)


func _exito(ficha_id: int, texto: String) -> Dictionary:
	return {"ok": true, "ficha_id": ficha_id, "mensaje": texto, "posiciones": posiciones()}


func _fallo(texto: String) -> Dictionary:
	return {"ok": false, "ficha_id": 0, "mensaje": texto, "posiciones": posiciones()}
