package mx.itson.parchis.p2p;

import java.util.Scanner;

/**
 * Prototipo del estilo (Hito 2A, punto 6): dos computadoras se mandan un mensaje.
 *
 * <pre>
 * PC 1:  PruebaP2P Ana 5000
 * PC 2:  PruebaP2P Beto 5000 192.168.1.10:5000
 * </pre>
 * Después, lo que se escriba en una consola aparece en la otra. "salir" termina.
 */
public class PruebaP2P {

    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.out.println("Uso: PruebaP2P <nombre> <puerto> [ip:puerto de otro peer ...]");
            return;
        }
        String nombre = args[0];
        int puerto = Integer.parseInt(args[1]);

        Peer peer = new Peer(nombre, puerto, new IReceptorMensajes() {
            @Override
            public void mensajeRecibido(Mensaje mensaje) {
                System.out.println("<< " + mensaje);
            }

            @Override
            public void peerConectado(String direccion) {
                System.out.println("** Conectado con " + direccion);
            }

            @Override
            public void peerDesconectado(String direccion) {
                System.out.println("** Se desconectó " + direccion);
            }
        });
        peer.iniciar();
        System.out.println(nombre + " escuchando en el puerto " + puerto);

        for (int i = 2; i < args.length; i++) {
            String[] partes = args[i].split(":");
            peer.conectar(partes[0], Integer.parseInt(partes[1]));
        }

        System.out.println("Escribe un mensaje y presiona Enter (\"salir\" para terminar).");
        try (Scanner teclado = new Scanner(System.in)) {
            while (teclado.hasNextLine()) {
                String texto = teclado.nextLine();
                if (texto.equalsIgnoreCase("salir")) {
                    break;
                }
                peer.difundir(texto);
            }
        }
        peer.detener();
    }
}
