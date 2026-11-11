package mx.itson.parchis.interfaces;

import java.util.List;
import mx.itson.parchis.dtos.JugadorDTO;

/**
 * Fachada del subsistema Sala. La presentación solo conoce esta interfaz;
 * la implementación (mock o real) la decide la fábrica.
 *
 * IMPORTANTE: no cambiar esta interfaz sin avisar al equipo y actualizar StarUML.
 */
public interface IFachadaSala {

    /** Máximo de jugadores en una sala. */
    int MAX_JUGADORES = 4;

    /**
     * CU-01 Registrar jugador.
     *
     * @param jugador nombre, color y avatar elegidos
     * @return el jugador tal como quedó registrado
     * @throws SalaException A1 datos incompletos, A2 nombre repetido,
     *                       A3 color ocupado o sala llena
     */
    JugadorDTO registrarJugador(JugadorDTO jugador) throws SalaException;

    /**
     * @return los jugadores registrados en la sala, en orden de registro
     */
    List<JugadorDTO> obtenerJugadores();
}
