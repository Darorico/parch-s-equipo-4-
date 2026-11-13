package mx.itson.parchis.fabricarsala;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.util.ArrayList;
import java.util.List;
import mx.itson.parchis.bos.PerfilBO;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.interfaces.SalaException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Pruebas del CU-01 Registrar jugador contra IFachadaSala: una por flujo.
 * La fachada se pide a la fábrica, así que sirven igual con el mock que con FachadaSala:
 * cuando la fábrica entregue la fachada real, estas pruebas la revisan sin cambiar nada.
 *
 * Con la fachada real necesitan MySQL y Config/config.properties; si no están, se saltan
 * en lugar de fallar. Al terminar cada prueba se borran los perfiles que guardó,
 * así la tabla perfil queda como estaba.
 */
class FachadaSalaTest {

    /**
     * La fachada real guarda el perfil en MySQL y el nombre es la llave de la tabla,
     * por eso cada corrida usa nombres distintos.
     */
    private static final String SUFIJO = Long.toString(System.currentTimeMillis() % 1_000_000);

    /** true si la fábrica va a entregar la fachada real (la que usa MySQL). */
    private static final boolean MODO_REAL = !FabricaSala.MODO_MOCK.equalsIgnoreCase(
            System.getProperty(FabricaSala.PROPIEDAD_MODO, FabricaSala.MODO_REAL));

    /** Solo se usa para limpiar la tabla perfil después de cada prueba. */
    private static PerfilBO perfiles;
    private static String motivoSinBase;

    private final List<String> nombresUsados = new ArrayList<>();
    private IFachadaSala fachada;

    @BeforeAll
    static void revisarBase() {
        if (!MODO_REAL) {
            return;
        }
        try {
            perfiles = new PerfilBO();
            perfiles.listar();
        } catch (IllegalStateException e) {
            perfiles = null;
            motivoSinBase = "Sin conexión a MySQL: " + e.getMessage();
        }
    }

    @BeforeEach
    void setUp() {
        assumeTrue(!MODO_REAL || perfiles != null, motivoSinBase);
        fachada = FabricaSala.crearFachada();
    }

    @AfterEach
    void limpiar() {
        if (perfiles != null) {
            for (String n : nombresUsados) {
                perfiles.eliminar(n);
            }
        }
    }

    private String nombre(String base) {
        String n = base + SUFIJO;
        nombresUsados.add(n);
        return n;
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
