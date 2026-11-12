package mx.itson.parchis.daos;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;

/**
 * Implementación MySQL de IPerfilDAO.
 * Todo el SQL de la aplicación para Perfil vive en esta clase.
 * La conexion se lee de config.properties (classpath o carpeta de trabajo)
 */
public class PerfilDAOMySQL implements IPerfilDAO {

    private static final String CONFIG_FILE = "config.properties";

    // ---------- SQL ----------
    private static final String SQL_INSERT =
            "INSERT INTO perfil (nombre, color, avatar) VALUES (?, ?, ?)";

    private static final String SQL_UPDATE =
            "UPDATE perfil SET color = ?, avatar = ? WHERE nombre = ?";

    private static final String SQL_DELETE =
            "DELETE FROM perfil WHERE nombre = ?";

    private static final String SQL_SELECT_BY_NOMBRE =
            "SELECT nombre, color, avatar FROM perfil WHERE nombre = ?";

    private static final String SQL_SELECT_ALL =
            "SELECT nombre, color, avatar FROM perfil ORDER BY nombre";

    // ---------- Configuración ----------
    private final String url;
    private final String user;
    private final String password;

    public PerfilDAOMySQL() {
        Properties props = cargarConfig();
        this.url = props.getProperty("db.url");
        this.user = props.getProperty("db.user");
        this.password = props.getProperty("db.password");

        if (url == null || user == null || password == null) {
            throw new IllegalStateException(
                    "Faltan db.url, db.user o db.password en " + CONFIG_FILE);
        }
    }

    private static Properties cargarConfig() {
        Properties props = new Properties();
        // 1) Classpath (por ejemplo src/main/resources)
        try (InputStream in = PerfilDAOMySQL.class.getClassLoader().getResourceAsStream(CONFIG_FILE)) {
            if (in != null) {
                props.load(in);
                return props;
            }
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo leer " + CONFIG_FILE + " del classpath", e);
        }
        // 2) Carpeta de trabajo
        try (InputStream in = new FileInputStream(CONFIG_FILE)) {
            props.load(in);
            return props;
        } catch (IOException e) {
            throw new IllegalStateException("No se encontro " + CONFIG_FILE, e);
        }
    }

    private Connection getConnection() throws SQLException {
        return DriverManager.getConnection(url, user, password);
    }

    // ---------- Operaciones ----------
    @Override
    public void insertar(JugadorDTO perfil) throws SQLException {
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_INSERT)) {

            ps.setString(1, perfil.getNombre());
            ps.setString(2, perfil.getColor().name());
            ps.setInt(3, perfil.getAvatar());
            ps.executeUpdate();
        }
    }

    @Override
    public boolean actualizar(JugadorDTO perfil) throws SQLException {
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_UPDATE)) {

            ps.setString(1, perfil.getColor().name());
            ps.setInt(2, perfil.getAvatar());
            ps.setString(3, perfil.getNombre());
            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean eliminar(String nombre) throws SQLException {
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_DELETE)) {

            ps.setString(1, nombre);
            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public JugadorDTO buscarPorNombre(String nombre) throws SQLException {
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_SELECT_BY_NOMBRE)) {

            ps.setString(1, nombre);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapear(rs) : null;
            }
        }
    }

    @Override
    public List<JugadorDTO> listar() throws SQLException {
        List<JugadorDTO> lista = new ArrayList<>();
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(SQL_SELECT_ALL);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                lista.add(mapear(rs));
            }
        }
        return lista;
    }

    private JugadorDTO mapear(ResultSet rs) throws SQLException {
        return new JugadorDTO(
                rs.getString("nombre"),
                ColorFicha.valueOf(rs.getString("color")),
                rs.getInt("avatar"));
    }
}