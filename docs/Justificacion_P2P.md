# Justificación del estilo: Peer-to-Peer (borrador)

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

Propuesta para el Hito 2B: cada registro se difunde con la hora en que se hizo y el nombre del jugador; si dos peers
reciben registros que chocan, **todos aplican la misma regla** (gana el registro más antiguo y, si empatan, el nombre
menor en orden alfabético). Como la regla es la misma en todos, todos llegan al mismo resultado sin necesitar servidor.
Al perdedor se le muestra el alterno A2 o A3.

## Prototipo
`ComunicacionP2P/PruebaP2P`: dos computadoras se conectan y se mandan mensajes de texto en ambos sentidos
(capturas en el Word).
