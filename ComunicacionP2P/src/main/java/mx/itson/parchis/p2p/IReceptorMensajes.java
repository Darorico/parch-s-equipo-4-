package mx.itson.parchis.p2p;

/**
 * Quien quiera enterarse de lo que llega por la red implementa esta interfaz (Observer).
 */
public interface IReceptorMensajes {

    /** Llegó un mensaje de otro peer. */
    void mensajeRecibido(Mensaje mensaje);

    /** Un peer se conectó (direccion = IP:puerto). */
    void peerConectado(String direccion);

    /** Un peer se desconectó (direccion = IP:puerto). */
    void peerDesconectado(String direccion);
}
