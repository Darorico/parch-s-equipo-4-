package mx.itson.parchis.sala;

import java.util.ArrayList;
import java.util.List;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.interfaces.IFachadaSala;

/**
 * Entidad interna del subsistema Sala: los jugadores que están en la sala de espera,
 * en orden de registro. Responde las preguntas del CU-01 (nombre disponible,
 * color disponible, sala llena); quién lanza las excepciones es FachadaSala.
 */
final class Sala {

    private final List<Jugador> jugadores = new ArrayList<>();

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

    void agregarJugador(Jugador jugador) {
        jugadores.add(jugador);
    }

    /** Copia de solo lectura, en orden de registro. */
    List<Jugador> getJugadores() {
        return List.copyOf(jugadores);
    }
}
