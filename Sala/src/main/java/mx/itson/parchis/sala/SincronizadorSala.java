package mx.itson.parchis.sala;

import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;
import mx.itson.parchis.p2p.IReceptorMensajes;
import mx.itson.parchis.p2p.Mensaje;
import mx.itson.parchis.p2p.Peer;

/**
 * Une el subsistema Sala con la red P2P (estilo de arquitectura del equipo).
 *
 * <ul>
 *   <li>Cuando un jugador se registra en este peer, su registro se difunde a los demás.</li>
 *   <li>Cuando llega un registro nuevo de otro peer, se aplica a la sala local y se reenvía,
 *       así llega a todos aunque no estén conectados directamente entre sí.</li>
 *   <li>Cuando se conecta un peer (por ejemplo, uno que arrancó tarde), se le mandan
 *       todos los registros conocidos para que su sala quede igual.</li>
 * </ul>
 *
 * Cada registro se procesa una sola vez: los repetidos (por el reenvío) se ignoran.
 * Es interna del subsistema: la presentación no sabe que existe.
 */
final class SincronizadorSala implements IReceptorMensajes {

    private static final Logger LOG = Logger.getLogger(SincronizadorSala.class.getName());

    private final FachadaSala fachada;
    /** Identifica a este peer en la red. */
    private final String id;
    /** Todos los registros que este peer ya conoce (propios y recibidos). */
    private final Set<RegistroRed> conocidos = ConcurrentHashMap.newKeySet();
    private Peer peer;

    SincronizadorSala(FachadaSala fachada, String id) {
        this.fachada = fachada;
        this.id = id;
    }

    /** Registra como conocidos los jugadores que ya estaban en la sala antes de conectarse. */
    void conocer(List<Jugador> jugadores) {
        for (Jugador j : jugadores) {
            conocidos.add(RegistroRed.de(j));
        }
    }

    /**
     * Abre el puerto de este peer y se conecta a los peers indicados.
     * Si un peer todavía no está corriendo no es error: cuando arranque,
     * él se conectará a este (si lo tiene en su lista).
     *
     * @param puerto puerto donde escucha este peer (0 = uno libre)
     * @param direcciones otros peers, con el formato ip:puerto
     * @throws IOException si no se pudo abrir el puerto
     */
    void iniciar(int puerto, List<String> direcciones) throws IOException {
        peer = new Peer(id, puerto, this);
        peer.iniciar();
        LOG.info(() -> "Peer " + id + " escuchando en el puerto " + peer.getPuerto());
        for (String direccion : direcciones) {
            conectar(direccion);
        }
    }

    private void conectar(String direccion) {
        int i = direccion.lastIndexOf(':');
        if (i <= 0) {
            LOG.warning(() -> "Dirección de peer inválida (se esperaba ip:puerto): " + direccion);
            return;
        }
        try {
            peer.conectar(direccion.substring(0, i).trim(), Integer.parseInt(direccion.substring(i + 1).trim()));
        } catch (IOException | NumberFormatException e) {
            LOG.log(Level.WARNING, "No se pudo conectar con " + direccion
                    + "; se conectará cuando ese peer arranque.", e);
        }
    }

    /** Difunde a los demás peers un jugador que se acaba de registrar aquí. */
    void difundirLocal(Jugador jugador) {
        RegistroRed registro = RegistroRed.de(jugador);
        conocidos.add(registro);
        peer.difundir(registro.aTexto());
    }

    int getPuerto() {
        return peer.getPuerto();
    }

    void detener() {
        if (peer != null) {
            peer.detener();
        }
    }

    // ---------- IReceptorMensajes: lo que llega de la red ----------

    @Override
    public void mensajeRecibido(Mensaje mensaje) {
        RegistroRed registro = RegistroRed.deTexto(mensaje.getContenido());
        if (registro == null) {
            LOG.fine(() -> "Mensaje ignorado: " + mensaje);
            return;
        }
        if (conocidos.add(registro)) {
            // Es nuevo: se aplica aquí y se reenvía para que llegue a todos los peers.
            fachada.aplicarRegistroRemoto(registro);
            peer.difundir(registro.aTexto());
        }
    }

    @Override
    public void peerConectado(String direccion) {
        LOG.info(() -> "Peer conectado: " + direccion);
        // Al recién llegado se le pasa todo lo que ya se conoce; los demás lo ignoran por repetido.
        for (RegistroRed registro : conocidos) {
            peer.difundir(registro.aTexto());
        }
    }

    @Override
    public void peerDesconectado(String direccion) {
        LOG.info(() -> "Peer desconectado: " + direccion);
    }
}
