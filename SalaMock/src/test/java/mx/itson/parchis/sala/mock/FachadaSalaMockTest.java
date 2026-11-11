package mx.itson.parchis.sala.mock;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.interfaces.SalaException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Pruebas del CU-01 Registrar jugador sobre el mock: una por flujo.
 */
class FachadaSalaMockTest {

    private FachadaSalaMock fachada;

    @BeforeEach
    void setUp() {
        fachada = new FachadaSalaMock();
    }

    @Test
    void registraJugadorFlujoNormal() throws SalaException {
        JugadorDTO ana = new JugadorDTO("Ana", ColorFicha.ROJO, 1);

        JugadorDTO registrado = fachada.registrarJugador(ana);

        assertEquals(ana, registrado);
        assertEquals(List.of(ana), fachada.obtenerJugadores());
    }

    @Test
    void fallaConDatosIncompletosA1() {
        SalaException e = assertThrows(SalaException.class,
                () -> fachada.registrarJugador(new JugadorDTO("  ", ColorFicha.ROJO, 1)));

        assertEquals(SalaException.Motivo.DATOS_INCOMPLETOS, e.getMotivo());
        assertEquals(0, fachada.obtenerJugadores().size());
    }

    @Test
    void fallaConNombreRepetidoA2() throws SalaException {
        fachada.registrarJugador(new JugadorDTO("Ana", ColorFicha.ROJO, 1));

        SalaException e = assertThrows(SalaException.class,
                () -> fachada.registrarJugador(new JugadorDTO("ana", ColorFicha.AZUL, 2)));

        assertEquals(SalaException.Motivo.NOMBRE_REPETIDO, e.getMotivo());
        assertEquals(1, fachada.obtenerJugadores().size());
    }

    @Test
    void fallaConColorOcupadoA3() throws SalaException {
        fachada.registrarJugador(new JugadorDTO("Ana", ColorFicha.ROJO, 1));

        SalaException e = assertThrows(SalaException.class,
                () -> fachada.registrarJugador(new JugadorDTO("Beto", ColorFicha.ROJO, 2)));

        assertEquals(SalaException.Motivo.COLOR_OCUPADO, e.getMotivo());
        assertEquals(1, fachada.obtenerJugadores().size());
    }

    @Test
    void fallaConSalaLlenaA3() throws SalaException {
        fachada.registrarJugador(new JugadorDTO("Ana", ColorFicha.ROJO, 1));
        fachada.registrarJugador(new JugadorDTO("Beto", ColorFicha.AZUL, 2));
        fachada.registrarJugador(new JugadorDTO("Carla", ColorFicha.AMARILLO, 3));
        fachada.registrarJugador(new JugadorDTO("Dani", ColorFicha.VERDE, 4));

        SalaException e = assertThrows(SalaException.class,
                () -> fachada.registrarJugador(new JugadorDTO("Eva", ColorFicha.ROJO, 1)));

        assertEquals(SalaException.Motivo.SALA_LLENA, e.getMotivo());
        assertEquals(4, fachada.obtenerJugadores().size());
    }
}
