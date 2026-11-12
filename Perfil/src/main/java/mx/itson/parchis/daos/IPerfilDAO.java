package mx.itson.parchis.daos;

import java.sql.SQLException;
import java.util.List;
import mx.itson.parchis.dtos.JugadorDTO;

public interface IPerfilDAO {


    void insertar(JugadorDTO perfil) throws SQLException;

    /** Actualiza color y avatar del perfil con ese nombre
     *  devuelve true si se modifico una fila
     * @param perfil
     * @return 
     * @throws java.sql.SQLException */
    boolean actualizar(JugadorDTO perfil) throws SQLException;

    /** Elimina por nombre devuelve true si se elimino una fila
     * @param nombre
     * @return
     * @throws java.sql.SQLException  */
    boolean eliminar(String nombre) throws SQLException;

    /** Devuelve el perfil o null si no existe
     * @param nombre
     * @return
     * @throws java.sql.SQLException  */
    JugadorDTO buscarPorNombre(String nombre) throws SQLException;

    List<JugadorDTO> listar() throws SQLException;
}