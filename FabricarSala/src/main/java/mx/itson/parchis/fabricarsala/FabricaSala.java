package mx.itson.parchis.fabricarsala;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.sala.FachadaSala;
import mx.itson.parchis.sala.mock.FachadaSalaMock;

/**
 * Crea la fachada del subsistema Sala. Es la única clase que conoce las implementaciones;
 * la presentación solo recibe IFachadaSala.
 *
 * Por defecto entrega la fachada real (FachadaSala, guarda el perfil en MySQL).
 * Con -Dparchis.sala=mock entrega el mock en memoria, por ejemplo para probar sin base de datos.
 *
 * @author pc
 */
public final class FabricaSala {

    public static final String PROPIEDAD_MODO = "parchis.sala";

    public static final String MODO_REAL = "real";
    public static final String MODO_MOCK = "mock";

    /** Puerto donde escucha este peer, por ejemplo -Dparchis.puerto=5000. Sin él no hay red. */
    public static final String PROPIEDAD_PUERTO = "parchis.puerto";
    /** Otros peers separados por coma, por ejemplo -Dparchis.peers=192.168.1.10:5000. */
    public static final String PROPIEDAD_PEERS = "parchis.peers";

    private FabricaSala() {
        // Evita crear instancias de esta clase
    }

    public static IFachadaSala crearFachada() {
        String modo = System.getProperty(PROPIEDAD_MODO, MODO_REAL);

        return switch (modo.toLowerCase()) {
            case MODO_REAL -> crearFachadaReal();
            case MODO_MOCK -> new FachadaSalaMock();
            default -> throw new IllegalArgumentException(
                    "Modo de sala no soportado: " + modo
            );
        };
    }

    /**
     * La fachada real. Si se indicó un puerto (-Dparchis.puerto=5000), además se conecta
     * con los demás peers (-Dparchis.peers=ip:puerto,ip:puerto); si no, funciona sin red.
     */
    private static FachadaSala crearFachadaReal() {
        FachadaSala fachada = new FachadaSala();
        String puerto = System.getProperty(PROPIEDAD_PUERTO, "").trim();
        if (puerto.isEmpty()) {
            return fachada;
        }
        List<String> peers = Arrays.stream(System.getProperty(PROPIEDAD_PEERS, "").split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
        try {
            fachada.conectarRed(Integer.parseInt(puerto), peers);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Puerto inválido en " + PROPIEDAD_PUERTO + ": " + puerto, e);
        } catch (IOException e) {
            throw new IllegalStateException("No se pudo abrir el puerto " + puerto
                    + " (¿ya hay otra instancia usándolo?)", e);
        }
        return fachada;
    }
}
