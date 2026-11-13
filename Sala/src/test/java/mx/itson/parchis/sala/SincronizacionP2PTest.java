package mx.itson.parchis.sala;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.BooleanSupplier;
import mx.itson.parchis.bos.PerfilBO;
import mx.itson.parchis.daos.IPerfilDAO;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.interfaces.SalaException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

/**
 * Pruebas del CU-01 en red: varias FachadaSala conectadas por P2P en esta misma computadora
 * (cada una en un puerto libre). El perfil se guarda en memoria para no necesitar MySQL.
 */
class SincronizacionP2PTest {

    /** Tiempo máximo para que un registro llegue a los demás peers. */
    private static final long ESPERA_MS = 3000;

    private final List<FachadaSala> peers = new ArrayList<>();

    @AfterEach
    void cerrar() {
        peers.forEach(FachadaSala::desconectarRed);
    }

    // ---------- Pruebas ----------

    @Test
    void elRegistroLlegaAlOtroPeer() throws Exception {
        FachadaSala pc1 = peer();
        FachadaSala pc2 = peer(pc1);

        pc1.registrarJugador(new JugadorDTO("Ana", ColorFicha.ROJO, 1));

        esperar(() -> pc2.obtenerJugadores().size() == 1, "el registro de Ana no llegó a la PC 2");
        assertEquals(new JugadorDTO("Ana", ColorFicha.ROJO, 1), pc2.obtenerJugadores().get(0));
    }

    @Test
    void funcionaEnLosDosSentidos() throws Exception {
        FachadaSala pc1 = peer();
        FachadaSala pc2 = peer(pc1);

        pc1.registrarJugador(new JugadorDTO("Ana", ColorFicha.ROJO, 1));
        esperar(() -> pc2.obtenerJugadores().size() == 1, "el registro de Ana no llegó a la PC 2");
        pc2.registrarJugador(new JugadorDTO("Beto", ColorFicha.AZUL, 2));

        esperar(() -> pc1.obtenerJugadores().size() == 2, "el registro de Beto no llegó a la PC 1");
        assertEquals(pc1.obtenerJugadores(), pc2.obtenerJugadores());
    }

    @Test
    void elQueSeConectaTardeRecibeALosQueYaEstaban() throws Exception {
        FachadaSala pc1 = peer();
        pc1.registrarJugador(new JugadorDTO("Ana", ColorFicha.ROJO, 1));

        FachadaSala pc2 = peer(pc1);

        esperar(() -> pc2.obtenerJugadores().size() == 1, "la PC 2 no recibió a Ana al conectarse");
    }

    @Test
    void elRegistroSeReenviaAPeersQueNoEstanConectadosDirecto() throws Exception {
        // PC 2 y PC 3 solo se conectan a PC 1; aun así se enteran entre ellas.
        FachadaSala pc1 = peer();
        FachadaSala pc2 = peer(pc1);
        FachadaSala pc3 = peer(pc1);

        pc2.registrarJugador(new JugadorDTO("Beto", ColorFicha.AZUL, 2));

        esperar(() -> pc3.obtenerJugadores().size() == 1, "el registro de Beto no llegó a la PC 3");
        assertEquals(pc2.obtenerJugadores(), pc3.obtenerJugadores());
    }

    @Test
    void losAlternosSeRevisanConLosJugadoresDeOtrosPeers() throws Exception {
        FachadaSala pc1 = peer();
        FachadaSala pc2 = peer(pc1);
        pc1.registrarJugador(new JugadorDTO("Ana", ColorFicha.ROJO, 1));
        esperar(() -> pc2.obtenerJugadores().size() == 1, "el registro de Ana no llegó a la PC 2");

        SalaException a2 = assertThrows(SalaException.class,
                () -> pc2.registrarJugador(new JugadorDTO("ana", ColorFicha.AZUL, 2)));
        SalaException a3 = assertThrows(SalaException.class,
                () -> pc2.registrarJugador(new JugadorDTO("Beto", ColorFicha.ROJO, 2)));

        assertEquals(SalaException.Motivo.NOMBRE_REPETIDO, a2.getMotivo());
        assertEquals(SalaException.Motivo.COLOR_OCUPADO, a3.getMotivo());
    }

    @Test
    void siDosPeersRegistranLoMismoAmbosSeQuedanConElMasAntiguo() throws Exception {
        // La PC 1 registra a Ana primero.
        FachadaSala pc1 = peer();
        pc1.registrarJugador(new JugadorDTO("Ana", ColorFicha.ROJO, 1));
        Thread.sleep(5);

        // La PC 2, que aún no se entera, registra el mismo nombre, el mismo color y otro jugador.
        FachadaSala pc2 = new FachadaSala(new PerfilBO(new PerfilDAOEnMemoria()));
        pc2.registrarJugador(new JugadorDTO("ana", ColorFicha.AZUL, 2));
        pc2.registrarJugador(new JugadorDTO("Beto", ColorFicha.ROJO, 3));
        pc2.registrarJugador(new JugadorDTO("Carla", ColorFicha.VERDE, 4));

        // Al conectarse se comparten los registros y las dos aplican la misma regla.
        pc2.conectarRed(0, List.of("127.0.0.1:" + pc1.getPuertoRed()));
        peers.add(pc2);

        List<JugadorDTO> esperado = List.of(
                new JugadorDTO("Ana", ColorFicha.ROJO, 1),
                new JugadorDTO("Carla", ColorFicha.VERDE, 4));
        esperar(() -> pc1.obtenerJugadores().equals(esperado) && pc2.obtenerJugadores().equals(esperado),
                "las PCs no llegaron a la misma sala: PC 1 = " + pc1.obtenerJugadores()
                + ", PC 2 = " + pc2.obtenerJugadores());
    }

    @Test
    void elMensajeRespetaNombresConCaracteresEspeciales() {
        RegistroRed original = new RegistroRed("Ñoño; José|1", ColorFicha.VERDE, 3, 1_700_000_000_123L, "abc12345");

        assertEquals(original, RegistroRed.deTexto(original.aTexto()));
    }

    @Test
    void ignoraMensajesQueNoSonRegistros() {
        assertNull(RegistroRed.deTexto("hola"));
        assertNull(RegistroRed.deTexto("REGISTRO;Ana;MORADO;1;5;abc"));
        assertNull(RegistroRed.deTexto("REGISTRO;Ana;ROJO;uno;5;abc"));
        assertNull(RegistroRed.deTexto(null));
    }

    // ---------- Ayudas ----------

    /** Crea un peer en un puerto libre y lo conecta a los peers indicados. */
    private FachadaSala peer(FachadaSala... conectarA) throws IOException {
        FachadaSala fachada = new FachadaSala(new PerfilBO(new PerfilDAOEnMemoria()));
        List<String> direcciones = new ArrayList<>();
        for (FachadaSala otro : conectarA) {
            direcciones.add("127.0.0.1:" + otro.getPuertoRed());
        }
        fachada.conectarRed(0, direcciones);
        peers.add(fachada);
        return fachada;
    }

    private static void esperar(BooleanSupplier condicion, String mensaje) throws InterruptedException {
        long limite = System.currentTimeMillis() + ESPERA_MS;
        while (System.currentTimeMillis() < limite) {
            if (condicion.getAsBoolean()) {
                return;
            }
            Thread.sleep(20);
        }
        assertTrue(condicion.getAsBoolean(), mensaje);
    }

    /** IPerfilDAO falso: guarda los perfiles en un mapa, sin MySQL. */
    private static final class PerfilDAOEnMemoria implements IPerfilDAO {

        private final Map<String, JugadorDTO> perfiles = new HashMap<>();

        @Override
        public void insertar(JugadorDTO perfil) {
            perfiles.put(perfil.getNombre(), perfil);
        }

        @Override
        public boolean actualizar(JugadorDTO perfil) {
            return perfiles.replace(perfil.getNombre(), perfil) != null;
        }

        @Override
        public boolean eliminar(String nombre) {
            return perfiles.remove(nombre) != null;
        }

        @Override
        public JugadorDTO buscarPorNombre(String nombre) {
            return perfiles.get(nombre);
        }

        @Override
        public List<JugadorDTO> listar() {
            return new ArrayList<>(perfiles.values());
        }
    }
}
