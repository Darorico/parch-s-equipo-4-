package mx.itson.parchis.sala;

import java.time.Instant;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;

/**
 * Entidad interna del subsistema Sala: un jugador que ya está en la sala.
 * Fuera del subsistema solo viaja su JugadorDTO.
 *
 * Guarda la hora de registro para poder aplicar la regla del P2P
 * "gana el registro más antiguo" cuando dos peers piden el mismo nombre o color.
 */
final class Jugador {

    private final String nombre;
    private final ColorFicha color;
    private final int avatar;
    private final Instant fechaRegistro;
    /** Peer donde se hizo el registro; desempata si dos registros tienen la misma hora y nombre. */
    private final String origen;

    Jugador(String nombre, ColorFicha color, int avatar) {
        this(nombre, color, avatar, Instant.now());
    }

    Jugador(String nombre, ColorFicha color, int avatar, Instant fechaRegistro) {
        this(nombre, color, avatar, fechaRegistro, "local");
    }

    Jugador(String nombre, ColorFicha color, int avatar, Instant fechaRegistro, String origen) {
        this.nombre = nombre;
        this.color = color;
        this.avatar = avatar;
        this.fechaRegistro = fechaRegistro;
        this.origen = origen;
    }

    String getOrigen() {
        return origen;
    }

    String getNombre() {
        return nombre;
    }

    ColorFicha getColor() {
        return color;
    }

    int getAvatar() {
        return avatar;
    }

    Instant getFechaRegistro() {
        return fechaRegistro;
    }

    JugadorDTO aDTO() {
        return new JugadorDTO(nombre, color, avatar);
    }
}
