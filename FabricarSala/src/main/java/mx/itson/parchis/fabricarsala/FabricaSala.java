package mx.itson.parchis.fabricarsala;

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

    private FabricaSala() {
        // Evita crear instancias de esta clase
    }

    public static IFachadaSala crearFachada() {
        String modo = System.getProperty(PROPIEDAD_MODO, MODO_REAL);

        return switch (modo.toLowerCase()) {
            case MODO_REAL -> new FachadaSala();
            case MODO_MOCK -> new FachadaSalaMock();
            default -> throw new IllegalArgumentException(
                    "Modo de sala no soportado: " + modo
            );
        };
    }
}
