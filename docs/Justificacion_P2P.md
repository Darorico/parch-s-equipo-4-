# Justificación del estilo: Peer-to-Peer

## El estilo
En P2P no hay un servidor central. Cada computadora (peer) es cliente y servidor a la vez: escucha conexiones y se
conecta a los demás. La información (por ejemplo, el registro de un jugador) se difunde a todos los peers, y cada uno
guarda su propia copia del estado de la sala.

## Escenarios de calidad y cómo los atiende P2P

| # | Atributo | Escenario | Cómo lo atiende P2P |
|---|---|---|---|
| EC-1 | Disponibilidad | Si un jugador cierra la aplicación o pierde la conexión durante la sala de espera, los demás siguen conectados y la sala no se cae. | No hay un punto único de falla: si se va un peer, solo se pierde su conexión (`Peer` avisa con `peerDesconectado`) y el resto sigue. |
| EC-2 | Rendimiento | Cuando un jugador se registra, los demás peers lo ven en la lista en menos de 1 segundo dentro de la misma red local. | El mensaje va directo de peer a peer, sin pasar por un intermediario. |
| EC-3 | Modificabilidad | Cambiar la implementación del subsistema Sala (mock → real) solo requiere modificar la fábrica. | La red está en su propio módulo (`ComunicacionP2P`) y la presentación solo conoce `IFachadaSala`. |

## Riesgo principal del estilo y cómo lo resolvemos
**Consistencia sin autoridad central.** Como no hay servidor que decida, dos peers podrían registrar el mismo color
(o el mismo nombre) casi al mismo tiempo y cada uno creer que es suyo.

En el Hito 2B la regla quedó implementada en el subsistema Sala:

- **Cada registro lleva su hora y su origen.** Viaja con la hora del registro en milisegundos y un identificador del
  peer donde se hizo (`RegistroRed`).
- **Cada peer guarda todas las solicitudes.** La sala no solo guarda a los jugadores aceptados, sino todas las
  solicitudes que conoce, propias y de otros peers (`Sala`).
- **Todos aplican la misma regla.** Las solicitudes se ordenan de la más antigua a la más nueva (si empatan en la hora,
  por nombre en orden alfabético y después por peer) y se aceptan en ese orden si su nombre y su color están libres y
  hay lugar. Como todos tienen las mismas solicitudes y aplican la misma regla, **todos llegan a la misma sala sin
  importar en qué orden les llegaron los mensajes**.
- **El que pierde se entera.** Si un jugador de esta computadora pierde su lugar, la pantalla le muestra el mensaje
  del flujo alterno A2 (nombre) o A3 (color) para que se registre otra vez.

**Limitación conocida:** la regla usa la hora de cada computadora. Si sus relojes están muy desfasados, puede ganar un
registro que en realidad se hizo después; aun así, todos los peers eligen al mismo ganador, así que la sala nunca queda
distinta entre ellos.

## Prototipo
`ComunicacionP2P/PruebaP2P`: dos computadoras se conectan y se mandan mensajes de texto en ambos sentidos
(capturas en el Word).

## Comunicación P2P en el CU-01 (Hito 2B)
El prototipo se conectó al subsistema Sala. Las clases nuevas son internas del subsistema: la presentación sigue usando
solo `IFachadaSala` y la interfaz de la fachada no cambió.

- **`RegistroRed`:** el registro de un jugador tal como viaja entre peers (nombre, color, avatar, hora y peer de origen).
- **`SincronizadorSala`:** une la sala con la red. Difunde los registros hechos aquí, aplica los que llegan de otros
  peers y los reenvía, así llegan a todos aunque no estén conectados directamente. Cada registro se procesa una sola vez.
- **Sincronización al conectarse:** cuando un peer se conecta (por ejemplo, uno que arrancó tarde), recibe todos los
  registros que ya existían.
- **Pantalla de registro:** revisa la sala cada medio segundo y se actualiza sola cuando llega un jugador de otra
  computadora.

La red se configura al arrancar la aplicación con opciones de la máquina virtual (VM Options en NetBeans); solo la
fábrica (`FabricaSala`) las lee:

- PC 1: `-Dparchis.puerto=5000`
- PC 2: `-Dparchis.puerto=5000 -Dparchis.peers=<IP de la PC 1>:5000`

Sin estas opciones la sala funciona sola, sin red.

**Pruebas:** el módulo Sala tiene pruebas automáticas (`SalaTest`, `SincronizacionP2PTest`) que conectan varias salas
por P2P en la misma computadora y comprueban que el registro llega a los demás, que el que se conecta tarde recibe a
los que ya estaban y que, cuando dos registros chocan, todas las salas se quedan con el más antiguo. La evidencia entre
dos computadoras se entrega con las capturas del CU-01.
