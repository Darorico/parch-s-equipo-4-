package mx.itson.parchis.daos;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Pruebas de PerfilDAOMySQL contra la base parchis real.
 * Necesitan MySQL y Config/config.properties; si no están, se saltan en lugar de fallar.
 * Cada prueba borra los perfiles que insertó, así la tabla queda como estaba.
 */
class PerfilDAOMySQLTest {

    private static PerfilDAOMySQL dao;
    private static String motivoSinBase;

    private final List<String> insertados = new ArrayList<>();
    private String nombre;

    @BeforeAll
    static void conectar() {
        try {
            dao = new PerfilDAOMySQL();
            dao.listar();
        } catch (IllegalStateException | SQLException e) {
            dao = null;
            motivoSinBase = "Sin conexión a MySQL: " + e.getMessage();
        }
    }

    @BeforeEach
    void setUp() {
        assumeTrue(dao != null, motivoSinBase);
        nombre = "prueba_" + System.nanoTime();
    }

    @AfterEach
    void limpiar() throws SQLException {
        for (String n : insertados) {
            dao.eliminar(n);
        }
    }

    private JugadorDTO insertar(String nombre, ColorFicha color, int avatar) throws SQLException {
        JugadorDTO perfil = new JugadorDTO(nombre, color, avatar);
        dao.insertar(perfil);
        insertados.add(nombre);
        return perfil;
    }

    @Test
    void insertaYBuscaPorNombre() throws SQLException {
        JugadorDTO perfil = insertar(nombre, ColorFicha.AMARILLO, 2);

        assertEquals(perfil, dao.buscarPorNombre(nombre));
    }

    @Test
    void buscarNombreInexistenteRegresaNull() throws SQLException {
        assertNull(dao.buscarPorNombre(nombre));
    }

    @Test
    void noInsertaNombreRepetido() throws SQLException {
        insertar(nombre, ColorFicha.ROJO, 1);

        assertThrows(SQLException.class,
                () -> dao.insertar(new JugadorDTO(nombre, ColorFicha.AZUL, 2)));
    }

    @Test
    void actualizaColorYAvatar() throws SQLException {
        insertar(nombre, ColorFicha.ROJO, 1);
        JugadorDTO cambiado = new JugadorDTO(nombre, ColorFicha.VERDE, 4);

        assertTrue(dao.actualizar(cambiado));
        assertEquals(cambiado, dao.buscarPorNombre(nombre));
    }

    @Test
    void actualizarInexistenteRegresaFalse() throws SQLException {
        assertFalse(dao.actualizar(new JugadorDTO(nombre, ColorFicha.ROJO, 1)));
    }

    @Test
    void eliminaPorNombre() throws SQLException {
        insertar(nombre, ColorFicha.AZUL, 3);

        assertTrue(dao.eliminar(nombre));
        assertNull(dao.buscarPorNombre(nombre));
        assertFalse(dao.eliminar(nombre));
    }

    @Test
    void listarIncluyeLosInsertados() throws SQLException {
        JugadorDTO uno = insertar(nombre + "_a", ColorFicha.ROJO, 1);
        JugadorDTO dos = insertar(nombre + "_b", ColorFicha.VERDE, 2);

        List<JugadorDTO> todos = dao.listar();

        assertTrue(todos.contains(uno));
        assertTrue(todos.contains(dos));
    }
}
