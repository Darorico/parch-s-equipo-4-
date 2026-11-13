package mx.itson.parchis.presentacion.control;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.ArrayList;
import java.util.List;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.interfaces.SalaException;
import mx.itson.parchis.interfaces.SalaException.Motivo;
import org.junit.jupiter.api.Test;

/**
 * Pruebas del aviso que ve el jugador cuando su registro pierde contra uno más antiguo
 * hecho en otra computadora (P2P). Una fachada falsa simula lo que llega por la red.
 */
class ControlSalaRedTest {

    private final SalaEnRed sala = new SalaEnRed();
    private final ControlSala control = new ControlSala(sala);

    @Test
    void sinCambiosNoHayAvisos() throws SalaException {
        control.registrarJugador("Ana", ColorFicha.ROJO, 1);

        assertTrue(control.registrosPerdidos().isEmpty());
    }

    @Test
    void siOtraComputadoraGanaElNombreSeAvisaConA2() throws SalaException {
        control.registrarJugador("Ana", ColorFicha.ROJO, 1);

        sala.llegaDeOtraComputadora(new JugadorDTO("ana", ColorFicha.AZUL, 2));

        List<SalaException> avisos = control.registrosPerdidos();
        assertEquals(1, avisos.size());
        assertEquals(Motivo.NOMBRE_REPETIDO, avisos.get(0).getMotivo());
    }

    @Test
    void siOtraComputadoraGanaElColorSeAvisaConA3() throws SalaException {
        control.registrarJugador("Ana", ColorFicha.ROJO, 1);

        sala.llegaDeOtraComputadora(new JugadorDTO("Beto", ColorFicha.ROJO, 2));

        assertEquals(Motivo.COLOR_OCUPADO, control.registrosPerdidos().get(0).getMotivo());
    }

    @Test
    void elAvisoSoloSeDaUnaVez() throws SalaException {
        control.registrarJugador("Ana", ColorFicha.ROJO, 1);
        sala.llegaDeOtraComputadora(new JugadorDTO("ana", ColorFicha.AZUL, 2));

        control.registrosPerdidos();

        assertTrue(control.registrosPerdidos().isEmpty());
    }

    @Test
    void soloSeAvisaDeLosJugadoresDeEstaComputadora() throws SalaException {
        sala.agregarRemoto(new JugadorDTO("Beto", ColorFicha.AZUL, 2));
        control.registrarJugador("Ana", ColorFicha.ROJO, 1);

        // Beto, que es de otra computadora, pierde contra Carla: aquí no se avisa nada.
        sala.llegaDeOtraComputadora(new JugadorDTO("Carla", ColorFicha.AZUL, 3));

        assertTrue(control.registrosPerdidos().isEmpty());
    }

    /**
     * Fachada falsa: registra como la real y deja simular un registro más antiguo que llega
     * de otro peer y saca a quien tenga el mismo nombre o el mismo color.
     */
    private static final class SalaEnRed implements IFachadaSala {

        private final List<JugadorDTO> jugadores = new ArrayList<>();

        @Override
        public JugadorDTO registrarJugador(JugadorDTO jugador) {
            jugadores.add(jugador);
            return jugador;
        }

        @Override
        public List<JugadorDTO> obtenerJugadores() {
            return List.copyOf(jugadores);
        }

        void agregarRemoto(JugadorDTO jugador) {
            jugadores.add(jugador);
        }

        void llegaDeOtraComputadora(JugadorDTO masAntiguo) {
            jugadores.removeIf(j -> j.getNombre().equalsIgnoreCase(masAntiguo.getNombre())
                    || j.getColor() == masAntiguo.getColor());
            jugadores.add(0, masAntiguo);
        }
    }
}
