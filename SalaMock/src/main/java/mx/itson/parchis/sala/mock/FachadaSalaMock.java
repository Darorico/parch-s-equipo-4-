package mx.itson.parchis.sala.mock;

import java.util.ArrayList;
import java.util.List;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.interfaces.SalaException;
import mx.itson.parchis.interfaces.SalaException.Motivo;

/**
 * Implementación simulada del subsistema Sala. Guarda los jugadores en memoria
 * y falla en los flujos alternos del CU-01 igual que lo hará la fachada real.
 */
public class FachadaSalaMock implements IFachadaSala {

    private final List<JugadorDTO> jugadores = new ArrayList<>();

    @Override
    public JugadorDTO registrarJugador(JugadorDTO jugador) throws SalaException {
        // A1: falta el nombre o el color
        if (jugador == null || jugador.getNombre() == null || jugador.getNombre().isBlank()
                || jugador.getColor() == null) {
            throw new SalaException(Motivo.DATOS_INCOMPLETOS, "Escribe tu nombre y elige un color.");
        }

        // A3: ya no cabe nadie
        if (jugadores.size() >= MAX_JUGADORES) {
            throw new SalaException(Motivo.SALA_LLENA,
                    "La sala ya está llena (" + MAX_JUGADORES + " jugadores).");
        }

        String nombre = jugador.getNombre().trim();
        for (JugadorDTO registrado : jugadores) {
            // A2: el nombre ya lo usa otro jugador
            if (registrado.getNombre().equalsIgnoreCase(nombre)) {
                throw new SalaException(Motivo.NOMBRE_REPETIDO,
                        "El nombre \"" + nombre + "\" ya está en uso. Elige otro.");
            }
            // A3: el color ya lo usa otro jugador
            if (registrado.getColor() == jugador.getColor()) {
                throw new SalaException(Motivo.COLOR_OCUPADO,
                        "El color " + jugador.getColor() + " ya está ocupado. Elige otro.");
            }
        }

        JugadorDTO nuevo = new JugadorDTO(nombre, jugador.getColor(), jugador.getAvatar());
        jugadores.add(nuevo);
        return nuevo;
    }

    @Override
    public List<JugadorDTO> obtenerJugadores() {
        return List.copyOf(jugadores);
    }
}
