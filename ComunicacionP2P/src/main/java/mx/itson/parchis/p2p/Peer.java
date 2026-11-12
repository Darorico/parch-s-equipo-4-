package mx.itson.parchis.p2p;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Nodo de la red P2P. No hay servidor central: cada peer escucha conexiones
 * entrantes y, a la vez, se puede conectar a otros peers. Un mensaje se
 * difunde a todos los peers conectados.
 */
public class Peer {

    private final String nombre;
    private final int puerto;
    private final IReceptorMensajes receptor;
    private final List<Conexion> conexiones = new CopyOnWriteArrayList<>();
    private ServerSocket servidor;

    public Peer(String nombre, int puerto, IReceptorMensajes receptor) {
        this.nombre = nombre;
        this.puerto = puerto;
        this.receptor = receptor;
    }

    /** Empieza a escuchar conexiones de otros peers. */
    public void iniciar() throws IOException {
        servidor = new ServerSocket(puerto);
        Thread hilo = new Thread(this::aceptarConexiones, "p2p-escucha");
        hilo.setDaemon(true);
        hilo.start();
    }

    /** Se conecta a otro peer que ya está escuchando. */
    public void conectar(String host, int puertoRemoto) throws IOException {
        agregar(new Socket(host, puertoRemoto));
    }

    /** Envía un mensaje a todos los peers conectados. */
    public void difundir(String contenido) {
        String linea = new Mensaje(nombre, contenido).aLinea();
        for (Conexion c : conexiones) {
            c.enviar(linea);
        }
    }

    public int getNumeroPeers() {
        return conexiones.size();
    }

    /** Cierra todas las conexiones. */
    public void detener() {
        for (Conexion c : conexiones) {
            c.cerrar();
        }
        try {
            if (servidor != null) {
                servidor.close();
            }
        } catch (IOException ignorada) {
            // ya estaba cerrado
        }
    }

    private void aceptarConexiones() {
        while (!servidor.isClosed()) {
            try {
                agregar(servidor.accept());
            } catch (IOException e) {
                // el servidor se cerró con detener()
            }
        }
    }

    private void agregar(Socket socket) throws IOException {
        Conexion conexion = new Conexion(socket);
        conexiones.add(conexion);
        receptor.peerConectado(conexion.direccion);
        Thread hilo = new Thread(conexion::leer, "p2p-" + conexion.direccion);
        hilo.setDaemon(true);
        hilo.start();
    }

    /** Una conexión con otro peer: una "tubería" de líneas de texto en cada sentido. */
    private class Conexion {

        private final Socket socket;
        private final PrintWriter salida;
        private final BufferedReader entrada;
        private final String direccion;

        Conexion(Socket socket) throws IOException {
            this.socket = socket;
            this.direccion = socket.getInetAddress().getHostAddress() + ":" + socket.getPort();
            this.salida = new PrintWriter(socket.getOutputStream(), true, StandardCharsets.UTF_8);
            this.entrada = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
        }

        void leer() {
            try {
                String linea;
                while ((linea = entrada.readLine()) != null) {
                    receptor.mensajeRecibido(Mensaje.deLinea(linea));
                }
            } catch (IOException e) {
                // el otro peer se fue
            } finally {
                cerrar();
            }
        }

        void enviar(String linea) {
            salida.println(linea);
        }

        void cerrar() {
            if (conexiones.remove(this)) {
                try {
                    socket.close();
                } catch (IOException ignorada) {
                    // ya estaba cerrado
                }
                receptor.peerDesconectado(direccion);
            }
        }
    }
}
