package mx.itson.parchis.sala;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.interfaces.IFachadaSala;

/**
 * Entidad interna del subsistema Sala: los jugadores que están en la sala de espera,
 * en orden de registro. Responde las preguntas del CU-01 (nombre disponible,
 * color disponible, sala llena); quién lanza las excepciones es FachadaSala.
 *
 * <h2>Regla del P2P: gana el registro más antiguo</h2>
 * Como no hay servidor, dos peers pueden registrar el mismo nombre o color casi al mismo
 * tiempo. Por eso la sala guarda todas las solicitudes de registro que conoce (propias y
 * de otros peers) y calcula quién queda dentro siempre de la misma forma:
 * <ol>
 *   <li>Ordena las solicitudes de la más antigua a la más nueva; si empatan en la hora,
 *       por nombre en orden alfabético (y, si también empatan, por el peer de origen).</li>
 *   <li>Las recorre en ese orden y deja entrar a cada una si su nombre y su color están
 *       libres y la sala no está llena.</li>
 * </ol>
 * Como todos los peers terminan conociendo las mismas solicitudes y aplican la misma regla,
 * todos llegan a la misma sala sin necesitar un servidor que decida, sin importar
 * en qué orden les llegaron los mensajes.
 */
final class Sala {

    /** Orden de la regla: más antiguo primero; empate por nombre y luego por peer de origen. */
    static final Comparator<Jugador> ORDEN = Comparator
            .comparing(Jugador::getFechaRegistro)
            .thenComparing(j -> j.getNombre().toLowerCase(Locale.ROOT))
            .thenComparing(Jugador::getOrigen);

    /** Todas las solicitudes de registro conocidas, aunque hayan perdido contra otra. */
    private final List<Jugador> solicitudes = new ArrayList<>();
    /** Los que quedaron dentro según la regla, en orden de registro. */
    private List<Jugador> jugadores = List.of();

    /** A2: nadie más usa ese nombre (sin distinguir mayúsculas). */
    boolean nombreDisponible(String nombre) {
        return jugadores.stream().noneMatch(j -> j.getNombre().equalsIgnoreCase(nombre));
    }

    /** A3: nadie más usa ese color. */
    boolean colorDisponible(ColorFicha color) {
        return jugadores.stream().noneMatch(j -> j.getColor() == color);
    }

    /** A3: ya hay MAX_JUGADORES en la sala. */
    boolean estaLlena() {
        return jugadores.size() >= IFachadaSala.MAX_JUGADORES;
    }

    /**
     * Agrega una solicitud de registro (de este peer o de otro) y vuelve a aplicar la regla.
     *
     * @return true si el jugador quedó dentro de la sala
     */
    boolean agregarJugador(Jugador jugador) {
        solicitudes.add(jugador);
        recalcular();
        return jugadores.contains(jugador);
    }

    /** Copia de solo lectura, en orden de registro. */
    List<Jugador> getJugadores() {
        return jugadores;
    }

    /** Todas las solicitudes conocidas, incluidas las que perdieron (para compartirlas en la red). */
    List<Jugador> getSolicitudes() {
        return List.copyOf(solicitudes);
    }

    /** Aplica la regla "gana el registro más antiguo" a todas las solicitudes. */
    private void recalcular() {
        List<Jugador> dentro = new ArrayList<>();
        for (Jugador candidato : solicitudes.stream().sorted(ORDEN).toList()) {
            boolean choca = dentro.stream().anyMatch(j ->
                    j.getNombre().equalsIgnoreCase(candidato.getNombre())
                    || j.getColor() == candidato.getColor());
            if (!choca && dentro.size() < IFachadaSala.MAX_JUGADORES) {
                dentro.add(candidato);
            }
        }
        jugadores = List.copyOf(dentro);
    }
}
