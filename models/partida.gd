class_name Partida
extends Node
## MODELO (MVC) y SUJETO OBSERVADO (patrón Observer).
##
## - Las vistas nunca consultan este objeto: se suscriben a sus señales y repintan con los datos que
##   trae cada señal.
## - En el servidor es el modelo autoritativo: ejecuta el caso de uso «Ejercer turno del juego» y delega
##   las reglas de negocio en la FachadaReglas (que por ahora usa un objeto Mock).
## - En cada cliente es una réplica: aplicar_evento() actualiza su estado con lo que manda el servidor
##   (CU09 Sincronizar Tablero) y emite exactamente la misma señal, así las vistas funcionan igual en
##   todos los equipos.

enum Estado { ESPERA, EN_CURSO, TERMINADA }

const MIN_JUGADORES := 2
const MAX_JUGADORES := 4

## Señales que el servidor replica en todos los clientes.
const SENALES_REPLICADAS: Array[StringName] = [
	&"jugador_registrado", &"jugadores_actualizados", &"partida_iniciada", &"turno_cambiado",
	&"dado_lanzado", &"opciones_turno", &"ficha_movida", &"mensaje", &"partida_terminada",
]

signal jugador_registrado(jugador_id: int)
signal jugadores_actualizados(jugadores: Array)
signal partida_iniciada(jugadores: Array, orden: Array)
signal turno_cambiado(jugador_id: int)
signal dado_lanzado(jugador_id: int, valor: int)
signal opciones_turno(jugador_id: int, fichas_movibles: Array, puede_liberar: bool)
signal ficha_movida(jugador_id: int, ficha_id: int, posiciones: Dictionary)
signal mensaje(texto: String)
signal partida_terminada(ganador_id: int, motivo: String)
## Solo local: un error dirigido a este equipo («No es tu turno», conexión perdida, etc.).
signal error_recibido(texto: String)
## Acompaña a cada señal replicada; el controlador de red lo escucha para difundirla (CU09).
signal evento_emitido(nombre: StringName, args: Array)

var estado: Estado = Estado.ESPERA
var jugadores: Dictionary = {}  # jugador_id -> Jugador
var turno := Turno.new()
var dado := Dado.new()
## Solo se usa en el servidor.
var fachada: FachadaReglas

var turno_actual: int:
	get:
		return turno.jugador_actual()


# ---------------------------------------------------------------------------
# Lado servidor (modelo autoritativo)
# ---------------------------------------------------------------------------

## CU01 Registrar Jugador.
func registrar_jugador(jugador_id: int, nombre: String, color: String, avatar: int) -> String:
	if estado != Estado.ESPERA:
		return "La partida ya comenzó; espera a que termine."
	if jugadores.has(jugador_id):
		return "Ya estás registrado."
	if jugadores.size() >= MAX_JUGADORES:
		return "La partida está llena (máximo %d jugadores)." % MAX_JUGADORES
	nombre = nombre.strip_edges().left(16)
	if nombre.is_empty():
		return "Escribe un nombre de usuario."
	if not color in Jugador.COLORES or _color_ocupado(color):
		color = _color_libre()
	jugadores[jugador_id] = Jugador.new(jugador_id, nombre, color, clampi(avatar, 0, 3))
	_notificar(&"jugador_registrado", [jugador_id])
	_notificar(&"jugadores_actualizados", [_jugadores_como_datos()])
	return ""


## CU02 Confirmar Estado.
func confirmar_estado(jugador_id: int, listo: bool) -> String:
	if estado != Estado.ESPERA or not jugadores.has(jugador_id):
		return "No puedes cambiar tu estado ahora."
	jugadores[jugador_id].listo = listo
	_notificar(&"jugadores_actualizados", [_jugadores_como_datos()])
	verificar_estado_partida()
	return ""


## Arranca la partida (CU03) cuando hay al menos 2 jugadores y todos confirmaron.
func verificar_estado_partida() -> void:
	if estado != Estado.ESPERA or jugadores.size() < MIN_JUGADORES:
		return
	for jugador: Jugador in jugadores.values():
		if not jugador.listo:
			return
	iniciar_partida()


## CU03 Iniciar Partida. Turnos en sentido horario; quien empieza se elige al azar.
func iniciar_partida() -> void:
	estado = Estado.EN_CURSO
	var orden: Array[int] = []
	var colores := {}
	for datos: Dictionary in _jugadores_como_datos():
		orden.append(datos.id)
		colores[datos.id] = datos.color
	fachada.iniciar_partida(colores)
	var primero: int = orden.pick_random()
	turno.iniciar(orden, primero)
	_notificar(&"partida_iniciada", [_jugadores_como_datos(), orden])
	_notificar(&"mensaje", ["¡Comienza la partida! El sistema eligió al azar a %s para empezar." % _nombre(primero)])
	_notificar(&"turno_cambiado", [primero])


## CU12 Ejercer Turno → CU04 Lanzar Dado.
func lanzar_dado(jugador_id: int) -> String:
	var error := _validar_turno(jugador_id, Turno.Fase.LANZAR)
	if error != "":
		return error
	var valor := dado.generar_valor(fachada)
	turno.tiros_seguidos += 1
	_notificar(&"dado_lanzado", [jugador_id, valor])

	var opciones := fachada.opciones(jugador_id, valor)
	var movibles: Array = opciones.movibles
	if movibles.is_empty() and not opciones.puede_liberar:
		_notificar(&"mensaje", ["%s sacó %d y no tiene fichas que mover (necesita un 5 para sacar una de casa)." % [_nombre(jugador_id), valor]])
		_finalizar_accion(jugador_id)
	else:
		turno.fase = Turno.Fase.ELEGIR_FICHA
		_notificar(&"opciones_turno", [jugador_id, movibles, opciones.puede_liberar])
	return ""


## CU05 Liberar Ficha (solo con un 5).
func liberar_ficha(jugador_id: int) -> String:
	var error := _validar_turno(jugador_id, Turno.Fase.ELEGIR_FICHA)
	if error != "":
		return error
	return _aplicar_resultado(jugador_id, fachada.liberar_ficha(jugador_id, dado.valor_actual))


## CU06 Mover Ficha.
func mover_ficha(jugador_id: int, ficha_id: int) -> String:
	var error := _validar_turno(jugador_id, Turno.Fase.ELEGIR_FICHA)
	if error != "":
		return error
	return _aplicar_resultado(jugador_id, fachada.mover_ficha(jugador_id, ficha_id, dado.valor_actual))


## CU10 Gestionar Abandono (y CU11 Declarar Ganador si queda un solo jugador).
func quitar_jugador(jugador_id: int) -> void:
	if not jugadores.has(jugador_id):
		return
	var nombre := _nombre(jugador_id)
	jugadores.erase(jugador_id)
	if jugadores.is_empty():
		reiniciar()
		return
	match estado:
		Estado.ESPERA:
			_notificar(&"jugadores_actualizados", [_jugadores_como_datos()])
			verificar_estado_partida()
		Estado.EN_CURSO:
			var era_su_turno := turno.quitar(jugador_id)
			fachada.retirar_jugador(jugador_id)
			_notificar(&"jugadores_actualizados", [_jugadores_como_datos()])
			_notificar(&"mensaje", ["%s abandonó la partida: sus fichas salen del tablero." % nombre])
			if jugadores.size() == 1:
				estado = Estado.TERMINADA
				_notificar(&"partida_terminada", [jugadores.keys()[0], "Los demás jugadores abandonaron la partida."])
			elif era_su_turno:
				_notificar(&"turno_cambiado", [turno.jugador_actual()])
		_:
			_notificar(&"jugadores_actualizados", [_jugadores_como_datos()])


func reiniciar() -> void:
	estado = Estado.ESPERA
	jugadores.clear()
	turno = Turno.new()
	dado = Dado.new()


# ---------------------------------------------------------------------------
# Lado cliente (réplica del modelo)
# ---------------------------------------------------------------------------

## Aplica un evento recibido del servidor y lo vuelve a emitir como señal local.
func aplicar_evento(nombre: StringName, args: Array) -> void:
	if not nombre in SENALES_REPLICADAS:
		return
	match String(nombre):
		"jugadores_actualizados":
			_cargar_jugadores(args[0])
		"partida_iniciada":
			estado = Estado.EN_CURSO
			_cargar_jugadores(args[0])
			var orden: Array[int] = []
			orden.assign(args[1])
			turno.iniciar(orden, orden[0] if not orden.is_empty() else 0)
		"turno_cambiado":
			turno.fijar_actual(args[0])
		"dado_lanzado":
			dado.valor_actual = args[1]
		"opciones_turno":
			turno.fase = Turno.Fase.ELEGIR_FICHA
		"ficha_movida":
			_actualizar_posiciones(args[2])
		"partida_terminada":
			estado = Estado.TERMINADA
	_notificar(nombre, args)


func notificar_error(texto: String) -> void:
	error_recibido.emit(texto)


# ---------------------------------------------------------------------------
# Internos
# ---------------------------------------------------------------------------

func _aplicar_resultado(jugador_id: int, resultado: Dictionary) -> String:
	if not resultado.ok:
		return resultado.mensaje
	_actualizar_posiciones(resultado.posiciones)
	_notificar(&"ficha_movida", [jugador_id, resultado.ficha_id, resultado.posiciones])
	_notificar(&"mensaje", ["%s: %s" % [_nombre(jugador_id), resultado.mensaje]])
	_finalizar_accion(jugador_id)
	return ""


## La fachada valida si el turno termina (CU13 Repetir Tiro); si termina, pasa al siguiente jugador.
func _finalizar_accion(jugador_id: int) -> void:
	if not fachada.validar_fin_turno(jugador_id, dado.valor_actual, turno.tiros_seguidos):
		turno.repetir()
		_notificar(&"mensaje", ["%s sacó 6: vuelve a tirar." % _nombre(jugador_id)])
		_notificar(&"turno_cambiado", [jugador_id])
		return
	if dado.valor_actual == 6 and turno.tiros_seguidos >= 3:
		_notificar(&"mensaje", ["%s ya tiró tres veces seguidas: el turno pasa." % _nombre(jugador_id)])
	_notificar(&"turno_cambiado", [turno.siguiente()])


func _validar_turno(jugador_id: int, fase: Turno.Fase) -> String:
	if estado != Estado.EN_CURSO:
		return "La partida no está en curso."
	if jugador_id != turno.jugador_actual():
		return "No es tu turno."
	if turno.fase != fase:
		return "Primero lanza el dado." if fase == Turno.Fase.ELEGIR_FICHA else "Ya lanzaste: elige una ficha."
	return ""


## Notifica a los observadores. Primero se difunde por red (CU09) y luego se emite la señal local,
## así el orden de los eventos es el mismo en el servidor y en los clientes.
func _notificar(nombre: StringName, args: Array) -> void:
	evento_emitido.emit(nombre, args)
	emit_signal.callv([nombre] + args)


func _cargar_jugadores(lista: Array) -> void:
	jugadores.clear()
	for datos: Dictionary in lista:
		jugadores[datos.id] = Jugador.desde_dict(datos)


func _actualizar_posiciones(posiciones: Dictionary) -> void:
	for jugador_id: int in posiciones:
		if jugadores.has(jugador_id):
			jugadores[jugador_id].actualizar_casillas(posiciones[jugador_id])


## Jugadores como datos planos, ordenados en sentido horario por color.
func _jugadores_como_datos() -> Array:
	var lista := jugadores.values()
	lista.sort_custom(func(a: Jugador, b: Jugador) -> bool:
		return Jugador.COLORES.find(a.color) < Jugador.COLORES.find(b.color))
	return lista.map(func(j: Jugador) -> Dictionary: return j.to_dict())


func _nombre(jugador_id: int) -> String:
	return jugadores[jugador_id].nombre if jugadores.has(jugador_id) else "Jugador %d" % jugador_id


func _color_ocupado(color: String) -> bool:
	for jugador: Jugador in jugadores.values():
		if jugador.color == color:
			return true
	return false


func _color_libre() -> String:
	for color in Jugador.COLORES:
		if not _color_ocupado(color):
			return color
	return Jugador.COLORES[0]
