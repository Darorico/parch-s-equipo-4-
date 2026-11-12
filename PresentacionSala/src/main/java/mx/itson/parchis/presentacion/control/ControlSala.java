package mx.itson.parchis.presentacion.control;

import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.fabricarsala.FabricaSala;
import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.interfaces.SalaException;

public class ControlSala {

    private final IFachadaSala fachada;

    public ControlSala(IFachadaSala fachada) {
        this.fachada = fachada;
    }


    public ControlSala() {
        this(FabricaSala.crearFachada());
    }

    public JugadorDTO registrarJugador(String nombre, ColorFicha color, int avatar) throws SalaException {
        return fachada.registrarJugador(new JugadorDTO(nombre, color, avatar));
    }

    public List<JugadorDTO> obtenerJugadores() {
        return fachada.obtenerJugadores();
    }

    public List<ColorFicha> coloresDisponibles() {
        Set<ColorFicha> usados = fachada.obtenerJugadores().stream()
                .map(JugadorDTO::getColor)
                .collect(Collectors.toSet());
        return Arrays.stream(ColorFicha.values())
                .filter(c -> !usados.contains(c))
                .toList();
    }

    public boolean salaLlena() {
        return fachada.obtenerJugadores().size() >= IFachadaSala.MAX_JUGADORES;
    }
}