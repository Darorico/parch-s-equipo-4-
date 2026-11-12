package mx.itson.parchis.fabricar;

import mx.itson.parchis.fabricarsala.FabricaSala;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.sala.mock.FachadaSalaMock;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

class FabricaSalaTest {

    @AfterEach
    void limpiarPropiedad() {
        System.clearProperty(FabricaSala.PROPIEDAD_MODO);
    }

    @Test
    void sinPropiedadCreaElMock() {
        IFachadaSala fachada = FabricaSala.crearFachada();

        assertNotNull(fachada);
        assertTrue(fachada instanceof FachadaSalaMock);
    }

    @Test
    void modoMockCreaElMock() {
        System.setProperty(FabricaSala.PROPIEDAD_MODO, "mock");

        assertTrue(FabricaSala.crearFachada() instanceof FachadaSalaMock);
    }

    @Test
    void cadaLlamadaDevuelveUnaFachadaNueva() {
        assertNotSame(FabricaSala.crearFachada(), FabricaSala.crearFachada());
    }

    @Test
    void modoDesconocidoLanzaExcepcion() {
        System.setProperty(FabricaSala.PROPIEDAD_MODO, "inexistente");

        assertThrows(IllegalArgumentException.class, FabricaSala::crearFachada);
    }
}