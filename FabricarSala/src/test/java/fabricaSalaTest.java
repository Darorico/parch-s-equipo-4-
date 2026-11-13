package mx.itson.parchis.fabricar;

import mx.itson.parchis.fabricarsala.FabricaSala;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.sala.FachadaSala;
import mx.itson.parchis.sala.mock.FachadaSalaMock;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class FabricaSalaTest {

    @AfterEach
    void limpiarPropiedad() {
        System.clearProperty(FabricaSala.PROPIEDAD_MODO);
    }

    /**
     * La fachada real lee Config/config.properties al crearse.
     * Si no está, la prueba se salta en lugar de fallar.
     */
    private static IFachadaSala crearRealOSaltar() {
        try {
            return FabricaSala.crearFachada();
        } catch (IllegalStateException e) {
            assumeTrue(false, "Sin Config/config.properties: " + e.getMessage());
            return null;
        }
    }

    @Test
    void sinPropiedadCreaLaFachadaReal() {
        IFachadaSala fachada = crearRealOSaltar();

        assertNotNull(fachada);
        assertTrue(fachada instanceof FachadaSala);
    }

    @Test
    void modoRealCreaLaFachadaReal() {
        System.setProperty(FabricaSala.PROPIEDAD_MODO, "real");

        assertTrue(crearRealOSaltar() instanceof FachadaSala);
    }

    @Test
    void modoMockCreaElMock() {
        System.setProperty(FabricaSala.PROPIEDAD_MODO, "mock");

        assertTrue(FabricaSala.crearFachada() instanceof FachadaSalaMock);
    }

    @Test
    void cadaLlamadaDevuelveUnaFachadaNueva() {
        assertNotSame(crearRealOSaltar(), crearRealOSaltar());
    }

    @Test
    void modoDesconocidoLanzaExcepcion() {
        System.setProperty(FabricaSala.PROPIEDAD_MODO, "inexistente");

        assertThrows(IllegalArgumentException.class, FabricaSala::crearFachada);
    }
}
