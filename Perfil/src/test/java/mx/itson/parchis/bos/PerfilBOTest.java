package mx.itson.parchis.bos;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import mx.itson.parchis.daos.IPerfilDAO;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Pruebas de las reglas de PerfilBO. No usan MySQL: el DAO es uno falso en memoria.
 */
class PerfilBOTest {

    /** DAO en memoria que cuenta las llamadas y puede simular una falla de la base. */
    private static class PerfilDAOFalso implements IPerfilDAO {

        private final Map<String, JugadorDTO> perfiles = new LinkedHashMap<>();
        private boolean fallar;
        private int llamadas;

        private void revisar() throws SQLException {
            llamadas++;
            if (fallar) {
                throw new SQLException("Base de datos no disponible");
            }
        }

        @Override
        public void insertar(JugadorDTO perfil) throws SQLException {
            revisar();
            perfiles.put(perfil.getNombre(), perfil);
        }

        @Override
        public boolean actualizar(JugadorDTO perfil) throws SQLException {
            revisar();
            return perfiles.replace(perfil.getNombre(), perfil) != null;
        }

        @Override
        public boolean eliminar(String nombre) throws SQLException {
            revisar();
            return perfiles.remove(nombre) != null;
        }

        @Override
        public JugadorDTO buscarPorNombre(String nombre) throws SQLException {
            revisar();
            return perfiles.get(nombre);
        }

        @Override
        public List<JugadorDTO> listar() throws SQLException {
            revisar();
            return new ArrayList<>(perfiles.values());
        }
    }

    private PerfilDAOFalso dao;
    private PerfilBO bo;

    @BeforeEach
    void setUp() {
        dao = new PerfilDAOFalso();
        bo = new PerfilBO(dao);
    }

    @Test
    void registraPerfilValido() {
        JugadorDTO ana = new JugadorDTO("Ana", ColorFicha.ROJO, 1);

        bo.registrar(ana);

        assertEquals(ana, bo.obtenerPorNombre("Ana"));
    }

    @Test
    void noRegistraPerfilNulo() {
        assertThrows(IllegalArgumentException.class, () -> bo.registrar(null));
        assertEquals(0, dao.llamadas);
    }

    @Test
    void noRegistraNombreVacio() {
        assertThrows(IllegalArgumentException.class,
                () -> bo.registrar(new JugadorDTO("   ", ColorFicha.ROJO, 1)));
        assertEquals(0, dao.llamadas);
    }

    @Test
    void noRegistraNombreDeMasDe50Caracteres() {
        String largo = "a".repeat(51);

        assertThrows(IllegalArgumentException.class,
                () -> bo.registrar(new JugadorDTO(largo, ColorFicha.ROJO, 1)));
        assertEquals(0, dao.llamadas);
    }

    @Test
    void registraNombreDe50Caracteres() {
        String justo = "a".repeat(50);

        bo.registrar(new JugadorDTO(justo, ColorFicha.ROJO, 1));

        assertEquals(1, bo.listar().size());
    }

    @Test
    void noRegistraSinColor() {
        assertThrows(IllegalArgumentException.class,
                () -> bo.registrar(new JugadorDTO("Ana", null, 1)));
        assertEquals(0, dao.llamadas);
    }

    @Test
    void noRegistraAvatarNegativo() {
        assertThrows(IllegalArgumentException.class,
                () -> bo.registrar(new JugadorDTO("Ana", ColorFicha.ROJO, -1)));
        assertEquals(0, dao.llamadas);
    }

    @Test
    void noRegistraNombreRepetido() {
        bo.registrar(new JugadorDTO("Ana", ColorFicha.ROJO, 1));

        assertThrows(IllegalArgumentException.class,
                () -> bo.registrar(new JugadorDTO("Ana", ColorFicha.AZUL, 2)));
        assertEquals(1, bo.listar().size());
    }

    @Test
    void errorDeLaBaseAlRegistrarSeVuelveIllegalState() {
        dao.fallar = true;

        IllegalStateException e = assertThrows(IllegalStateException.class,
                () -> bo.registrar(new JugadorDTO("Ana", ColorFicha.ROJO, 1)));
        assertTrue(e.getCause() instanceof SQLException);
    }

    @Test
    void actualizaColorYAvatar() {
        bo.registrar(new JugadorDTO("Ana", ColorFicha.ROJO, 1));
        JugadorDTO cambiado = new JugadorDTO("Ana", ColorFicha.VERDE, 3);

        assertTrue(bo.actualizar(cambiado));
        assertEquals(cambiado, bo.obtenerPorNombre("Ana"));
    }

    @Test
    void actualizarPerfilInexistenteRegresaFalse() {
        assertFalse(bo.actualizar(new JugadorDTO("Nadie", ColorFicha.ROJO, 1)));
    }

    @Test
    void noActualizaPerfilInvalido() {
        assertThrows(IllegalArgumentException.class,
                () -> bo.actualizar(new JugadorDTO("Ana", null, 1)));
        assertEquals(0, dao.llamadas);
    }

    @Test
    void eliminaPerfil() {
        bo.registrar(new JugadorDTO("Ana", ColorFicha.ROJO, 1));

        assertTrue(bo.eliminar("Ana"));
        assertFalse(bo.eliminar("Ana"));
        assertNull(bo.obtenerPorNombre("Ana"));
    }

    @Test
    void eliminarYConsultarPidenNombre() {
        assertThrows(IllegalArgumentException.class, () -> bo.eliminar(" "));
        assertThrows(IllegalArgumentException.class, () -> bo.obtenerPorNombre(null));
        assertEquals(0, dao.llamadas);
    }

    @Test
    void obtenerPerfilInexistenteRegresaNull() {
        assertNull(bo.obtenerPorNombre("Nadie"));
    }

    @Test
    void listaLosPerfilesRegistrados() {
        bo.registrar(new JugadorDTO("Ana", ColorFicha.ROJO, 1));
        bo.registrar(new JugadorDTO("Beto", ColorFicha.AZUL, 2));

        assertEquals(2, bo.listar().size());
    }

    @Test
    void erroresDeLaBaseEnLasConsultasSeVuelvenIllegalState() {
        dao.fallar = true;

        assertThrows(IllegalStateException.class, () -> bo.listar());
        assertThrows(IllegalStateException.class, () -> bo.obtenerPorNombre("Ana"));
        assertThrows(IllegalStateException.class, () -> bo.eliminar("Ana"));
        assertThrows(IllegalStateException.class,
                () -> bo.actualizar(new JugadorDTO("Ana", ColorFicha.ROJO, 1)));
    }
}
