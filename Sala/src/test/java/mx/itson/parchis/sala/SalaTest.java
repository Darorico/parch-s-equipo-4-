package mx.itson.parchis.sala;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import mx.itson.parchis.dtos.ColorFicha;
import org.junit.jupiter.api.Test;

/**
 * Pruebas de la regla del P2P "gana el registro más antiguo" en la entidad Sala.
 * Las horas se ponen a mano para que cada caso sea exacto.
 */
class SalaTest {

    private static Jugador jugador(String nombre, ColorFicha color, long hora, String peer) {
        return new Jugador(nombre, color, 1, Instant.ofEpochMilli(hora), peer);
    }

    private static List<String> nombres(Sala sala) {
        return sala.getJugadores().stream().map(Jugador::getNombre).toList();
    }

    @Test
    void mismoNombreGanaElRegistroMasAntiguoAunqueLlegueDespues() {
        Sala sala = new Sala();
        sala.agregarJugador(jugador("Ana", ColorFicha.ROJO, 200, "pc1"));

        // Llega de otro peer un "ana" que se registró antes: se queda él y sale el local.
        boolean entro = sala.agregarJugador(jugador("ana", ColorFicha.AZUL, 100, "pc2"));

        assertTrue(entro);
        assertEquals(List.of("ana"), nombres(sala));
    }

    @Test
    void mismoNombreSiElRemotoEsMasNuevoNoEntra() {
        Sala sala = new Sala();
        sala.agregarJugador(jugador("Ana", ColorFicha.ROJO, 100, "pc1"));

        boolean entro = sala.agregarJugador(jugador("Ana", ColorFicha.AZUL, 200, "pc2"));

        assertFalse(entro);
        assertEquals(List.of("Ana"), nombres(sala));
        assertEquals(ColorFicha.ROJO, sala.getJugadores().get(0).getColor());
    }

    @Test
    void mismoColorGanaElRegistroMasAntiguo() {
        Sala sala = new Sala();
        sala.agregarJugador(jugador("Beto", ColorFicha.VERDE, 300, "pc1"));

        sala.agregarJugador(jugador("Carla", ColorFicha.VERDE, 250, "pc2"));

        assertEquals(List.of("Carla"), nombres(sala));
    }

    @Test
    void siEmpatanEnLaHoraGanaElNombreMenorEnOrdenAlfabetico() {
        Sala sala = new Sala();
        sala.agregarJugador(jugador("Beto", ColorFicha.ROJO, 100, "pc1"));

        sala.agregarJugador(jugador("Ana", ColorFicha.ROJO, 100, "pc2"));

        assertEquals(List.of("Ana"), nombres(sala));
    }

    @Test
    void losJugadoresSinConflictoQuedanEnOrdenDeRegistro() {
        Sala sala = new Sala();
        sala.agregarJugador(jugador("Dani", ColorFicha.VERDE, 400, "pc1"));
        sala.agregarJugador(jugador("Ana", ColorFicha.ROJO, 100, "pc2"));
        sala.agregarJugador(jugador("Carla", ColorFicha.AMARILLO, 300, "pc3"));
        sala.agregarJugador(jugador("Beto", ColorFicha.AZUL, 200, "pc4"));

        assertEquals(List.of("Ana", "Beto", "Carla", "Dani"), nombres(sala));
        assertTrue(sala.estaLlena());
    }

    @Test
    void todosLosPeersLleganALaMismaSalaSinImportarElOrdenDeLosMensajes() {
        List<Jugador> solicitudes = List.of(
                jugador("Ana", ColorFicha.ROJO, 500, "pc1"),
                jugador("ana", ColorFicha.AZUL, 300, "pc2"),
                jugador("Beto", ColorFicha.AZUL, 400, "pc3"),
                jugador("Carla", ColorFicha.VERDE, 100, "pc4"),
                jugador("Dani", ColorFicha.VERDE, 100, "pc1"),
                jugador("Eva", ColorFicha.AMARILLO, 600, "pc2"),
                jugador("Fer", ColorFicha.ROJO, 700, "pc3"));

        Sala referencia = new Sala();
        solicitudes.forEach(referencia::agregarJugador);

        Random azar = new Random(4);
        for (int i = 0; i < 50; i++) {
            List<Jugador> revueltas = new ArrayList<>(solicitudes);
            Collections.shuffle(revueltas, azar);
            Sala otroPeer = new Sala();
            revueltas.forEach(otroPeer::agregarJugador);

            assertEquals(nombres(referencia), nombres(otroPeer), "orden de llegada: " + revueltas.size());
        }
        // ana (300) gana a Ana (500) y saca a Beto (AZUL, 400); Carla gana a Dani por nombre.
        assertEquals(List.of("Carla", "ana", "Eva", "Fer"), nombres(referencia));
    }
}
