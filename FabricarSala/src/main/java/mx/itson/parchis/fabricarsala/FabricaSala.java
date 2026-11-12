package mx.itson.parchis.fabricarsala;

import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.sala.mock.FachadaSalaMock;

/**
 * creacion de sala 
 * @author pc
 */
public final class FabricaSala {

    public static final String PROPIEDAD_MODO = "parchis.sala";
    
    private FabricaSala() {
        // Evita crear instancias de esta clase
    }

    public static IFachadaSala crearFachada() {
        String modo = System.getProperty(PROPIEDAD_MODO, "mock");

        return switch (modo.toLowerCase()) {
            case "mock" -> new FachadaSalaMock();
            default -> throw new IllegalArgumentException(
                    "Modo de sala no soportado: " + modo
            );
        };
    }
}
