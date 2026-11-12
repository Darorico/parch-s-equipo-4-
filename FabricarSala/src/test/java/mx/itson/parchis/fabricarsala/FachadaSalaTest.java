package mx.itson.parchis.fabricarsala;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.interfaces.SalaException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Pruebas del CU-01 Registrar jugador contra IFachadaSala: una por flujo.
 * La fachada se pide a la fábrica, así que sirven igual con el mock que con FachadaSala:
 * cuando la fábrica entregue la fachada real, estas pruebas la revisan sin cambiar nada.
 */
class FachadaSalaTest {

    /**
     * La fachada real guarda el perfil en MySQL y el nombre es la llave de la tabla,
     * por eso cada corrida usa nombres distintos.
     */
    private static final String SUFIJO = Long.toString(System.currentTimeMillis() % 1_000_000);

    private IFachadaSala fachada;

    @BeforeEach
    void setUp() {
        fachada = FabricaSala.crearFachada();
    }

    private static String nombre(String base) {
        return base + SUFIJO;
    }

    @Test
    void registraJugadorFlujoNormal() throws SalaException {
        JugadorDTO ana = new JugadorDTO(nombre("Ana"), ColorFicha.ROJO, 1);

        JugadorDTO registrado = fachada.registrarJugador(ana);

        assertEquals(ana.getNombre(), registrado.getNombre());
        assertEquals(ana.getColor(), registrado.getColor());
        assertEquals(ana.getAvatar(), registrado.getAvatar());
        assertTrue(fachada.obtenerJugadores().contains(registrado));
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
        fachada.registrarJugador(new JugadorDTO(nombre("Beto"), ColorFicha.ROJO, 1));

        SalaException e = assertThrows(SalaException.class,
                () -> fachada.registrarJugador(new JugadorDTO(nombre("Beto"), ColorFicha.AZUL, 2)));

        assertEquals(SalaException.Motivo.NOMBRE_REPETIDO, e.getMotivo());
        assertEquals(1, fachada.obtenerJugadores().size());
    }

    @Test
    void fallaConColorOcupadoA3() throws SalaException {
        fachada.registrarJugador(new JugadorDTO(nombre("Carla"), ColorFicha.ROJO, 1));

        SalaException e = assertThrows(SalaException.class,
                () -> fachada.registrarJugador(new JugadorDTO(nombre("Dani"), ColorFicha.ROJO, 2)));

        assertEquals(SalaException.Motivo.COLOR_OCUPADO, e.getMotivo());
        assertEquals(1, fachada.obtenerJugadores().size());
    }

    @Test
    void fallaConSalaLlenaA3() throws SalaException {
        fachada.registrarJugador(new JugadorDTO(nombre("Eva"), ColorFicha.ROJO, 1));
        fachada.registrarJugador(new JugadorDTO(nombre("Fer"), ColorFicha.AZUL, 2));
        fachada.registrarJugador(new JugadorDTO(nombre("Gael"), ColorFicha.AMARILLO, 3));
        fachada.registrarJugador(new JugadorDTO(nombre("Hugo"), ColorFicha.VERDE, 4));

        SalaException e = assertThrows(SalaException.class,
                () -> fachada.registrarJugador(new JugadorDTO(nombre("Ivan"), ColorFicha.ROJO, 1)));

        assertEquals(SalaException.Motivo.SALA_LLENA, e.getMotivo());
        assertEquals(IFachadaSala.MAX_JUGADORES, fachada.obtenerJugadores().size());
    }
}
