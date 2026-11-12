package mx.itson.parchis.p2p;

/**
 * Mensaje que viaja entre peers. En el cable es una línea de texto: {@code remitente|contenido}.
 */
public class Mensaje {

    private static final String SEPARADOR = "|";

    private final String remitente;
    private final String contenido;

    public Mensaje(String remitente, String contenido) {
        this.remitente = remitente;
        this.contenido = contenido;
    }

    public String getRemitente() {
        return remitente;
    }

    public String getContenido() {
        return contenido;
    }

    /** Convierte el mensaje a una sola línea para enviarlo. */
    public String aLinea() {
        return remitente + SEPARADOR + contenido.replace('\n', ' ');
    }

    /** Reconstruye un mensaje a partir de la línea recibida. */
    public static Mensaje deLinea(String linea) {
        int i = linea.indexOf(SEPARADOR);
        if (i < 0) {
            return new Mensaje("?", linea);
        }
        return new Mensaje(linea.substring(0, i), linea.substring(i + 1));
    }

    @Override
    public String toString() {
        return remitente + ": " + contenido;
    }
}
