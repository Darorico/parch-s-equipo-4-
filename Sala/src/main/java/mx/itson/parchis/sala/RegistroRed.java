package mx.itson.parchis.sala;

import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import mx.itson.parchis.dtos.ColorFicha;

/**
 * Registro de un jugador tal como viaja entre peers (CU-01 en red).
 *
 * Lleva la hora de registro en milisegundos y el peer donde se hizo, para que todos
 * los peers puedan aplicar la misma regla cuando dos registros chocan.
 * En la red es una sola línea: {@code REGISTRO;nombre;color;avatar;milisegundos;origen}
 * (el nombre va codificado para que un ";" en el nombre no rompa el mensaje).
 *
 * Es un record: dos registros con los mismos datos son el mismo registro,
 * así cada peer reconoce los que ya conoce y no los procesa dos veces.
 */
record RegistroRed(String nombre, ColorFicha color, int avatar, long milisegundos, String origen) {

    private static final String TIPO = "REGISTRO";
    private static final String SEPARADOR = ";";

    /** Registro que corresponde a un jugador de la sala. */
    static RegistroRed de(Jugador jugador) {
        return new RegistroRed(jugador.getNombre(), jugador.getColor(), jugador.getAvatar(),
                jugador.getFechaRegistro().toEpochMilli(), jugador.getOrigen());
    }

    /** Convierte el registro a la línea que se manda por la red. */
    String aTexto() {
        return String.join(SEPARADOR, TIPO,
                URLEncoder.encode(nombre, StandardCharsets.UTF_8),
                color.name(),
                Integer.toString(avatar),
                Long.toString(milisegundos),
                origen);
    }

    /**
     * Reconstruye un registro a partir de la línea recibida.
     *
     * @return el registro, o null si la línea no es un registro válido
     *         (así un mensaje desconocido o dañado no tumba la aplicación)
     */
    static RegistroRed deTexto(String texto) {
        if (texto == null) {
            return null;
        }
        String[] partes = texto.split(SEPARADOR, -1);
        if (partes.length != 6 || !TIPO.equals(partes[0])) {
            return null;
        }
        try {
            String nombre = URLDecoder.decode(partes[1], StandardCharsets.UTF_8);
            if (nombre.isBlank() || partes[5].isBlank()) {
                return null;
            }
            return new RegistroRed(nombre, ColorFicha.valueOf(partes[2]),
                    Integer.parseInt(partes[3]), Long.parseLong(partes[4]), partes[5]);
        } catch (IllegalArgumentException e) {
            // color, número o codificación inválidos (NumberFormatException también entra aquí)
            return null;
        }
    }
}
