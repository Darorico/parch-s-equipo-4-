package mx.itson.parchis.presentacion.control;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.interfaces.SalaException;
import mx.itson.parchis.interfaces.SalaException.Motivo;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ControlSalaTest {

    private ControlSala control;

    @BeforeEach
    void preparar() {
        control = new ControlSala();
    }

    @Test
    void registroExitosoApareceEnLaLista() throws SalaException {
        JugadorDTO j = control.registrarJugador("Ana", ColorFicha.ROJO, 0);

        assertEquals("Ana", j.getNombre());
        assertEquals(1, control.obtenerJugadores().size());
    }

    @Test
    void nombreVacioLanzaDatosIncompletos() {
        SalaException ex = assertThrows(SalaException.class,
                () -> control.registrarJugador("   ", ColorFicha.ROJO, 0));
        assertEquals(Motivo.DATOS_INCOMPLETOS, ex.getMotivo());
    }

    @Test
    void sinColorLanzaDatosIncompletos() {
        SalaException ex = assertThrows(SalaException.class,
                () -> control.registrarJugador("Ana", null, 0));
        assertEquals(Motivo.DATOS_INCOMPLETOS, ex.getMotivo());
    }

    @Test
    void nombreRepetidoLanzaNombreRepetido() throws SalaException {
        control.registrarJugador("Ana", ColorFicha.ROJO, 0);

        SalaException ex = assertThrows(SalaException.class,
                () -> control.registrarJugador("ANA", ColorFicha.AZUL, 1));
        assertEquals(Motivo.NOMBRE_REPETIDO, ex.getMotivo());
    }

    @Test
    void colorRepetidoLanzaColorOcupado() throws SalaException {
        control.registrarJugador("Ana", ColorFicha.ROJO, 0);

        SalaException ex = assertThrows(SalaException.class,
                () -> control.registrarJugador("Beto", ColorFicha.ROJO, 1));
        assertEquals(Motivo.COLOR_OCUPADO, ex.getMotivo());
    }

    @Test
    void quintoJugadorLanzaSalaLlena() throws SalaException {
        llenarSala();

        SalaException ex = assertThrows(SalaException.class,
                () -> control.registrarJugador("Eva", ColorFicha.ROJO, 0));
        assertEquals(Motivo.SALA_LLENA, ex.getMotivo());
    }

    @Test
    void salaLlenaEsTrueConCuatroJugadores() throws SalaException {
        assertFalse(control.salaLlena());
        llenarSala();
        assertTrue(control.salaLlena());
    }

    @Test
    void coloresDisponiblesBajanConCadaRegistro() throws SalaException {
        assertEquals(4, control.coloresDisponibles().size());

        control.registrarJugador("Ana", ColorFicha.ROJO, 0);

        assertEquals(3, control.coloresDisponibles().size());
        assertFalse(control.coloresDisponibles().contains(ColorFicha.ROJO));
    }

    private void llenarSala() throws SalaException {
        control.registrarJugador("Ana", ColorFicha.ROJO, 0);
        control.registrarJugador("Beto", ColorFicha.AZUL, 1);
        control.registrarJugador("Carla", ColorFicha.AMARILLO, 2);
        control.registrarJugador("Dani", ColorFicha.VERDE, 3);
    }
}