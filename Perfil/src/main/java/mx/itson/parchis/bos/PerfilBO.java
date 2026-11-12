package mx.itson.parchis.bos;

import java.sql.SQLException;
import java.util.List;
import mx.itson.parchis.daos.IPerfilDAO;
import mx.itson.parchis.daos.PerfilDAOMySQL;
import mx.itson.parchis.dtos.JugadorDTO;

/**
 * Logica de negocio de Perfil: validaciones y reglas
 */
public class PerfilBO {

    private static final int NOMBRE_MAX = 50;

    private final IPerfilDAO perfilDAO;

    public PerfilBO() {
        this(new PerfilDAOMySQL());
    }

    public PerfilBO(IPerfilDAO perfilDAO) {
        this.perfilDAO = perfilDAO;
    }

    public void registrar(JugadorDTO perfil) {
        validar(perfil);
        try {
            if (perfilDAO.buscarPorNombre(perfil.getNombre()) != null) {
                throw new IllegalArgumentException("Ya existe un perfil con el nombre " + perfil.getNombre());
            }
            perfilDAO.insertar(perfil);
        } catch (SQLException e) {
            throw new IllegalStateException("Error al registrar el perfil", e);
        }
    }

    public boolean actualizar(JugadorDTO perfil) {
        validar(perfil);
        try {
            return perfilDAO.actualizar(perfil);
        } catch (SQLException e) {
            throw new IllegalStateException("Error al actualizar el perfil", e);
        }
    }

    public boolean eliminar(String nombre) {
        if (vacio(nombre)) {
            throw new IllegalArgumentException("El nombre es obligatorio");
        }
        try {
            return perfilDAO.eliminar(nombre);
        } catch (SQLException e) {
            throw new IllegalStateException("Error al eliminar el perfil", e);
        }
    }

    public JugadorDTO obtenerPorNombre(String nombre) {
        if (vacio(nombre)) {
            throw new IllegalArgumentException("El nombre es obligatorio");
        }
        try {
            return perfilDAO.buscarPorNombre(nombre);
        } catch (SQLException e) {
            throw new IllegalStateException("Error al consultar el perfil", e);
        }
    }

    public List<JugadorDTO> listar() {
        try {
            return perfilDAO.listar();
        } catch (SQLException e) {
            throw new IllegalStateException("Error al listar los perfiles", e);
        }
    }

    private void validar(JugadorDTO p) {
        if (p == null) {
            throw new IllegalArgumentException("El perfil no puede ser nulo");
        }
        if (vacio(p.getNombre()) || p.getNombre().length() > NOMBRE_MAX) {
            throw new IllegalArgumentException("El nombre es obligatorio (máx. " + NOMBRE_MAX + " caracteres)");
        }
        if (p.getColor() == null) {
            throw new IllegalArgumentException("El color de ficha es obligatorio");
        }
        if (p.getAvatar() < 0) {
            throw new IllegalArgumentException("El avatar es invalido");
        }
    }

    private boolean vacio(String s) {
        return s == null || s.trim().isEmpty();
    }
}