package mx.itson.parchis.presentacion.control;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.fabricarsala.FabricaSala;
import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.interfaces.SalaException;
import mx.itson.parchis.interfaces.SalaException.Motivo;

public class ControlSala {

    private final IFachadaSala fachada;
    /** Jugadores que se registraron desde esta computadora. */
    private final List<JugadorDTO> registradosAqui = new ArrayList<>();
    /** Jugadores de esta computadora a los que ya se les avisó que salieron de la sala. */
    private final Set<JugadorDTO> yaAvisados = new HashSet<>();

    public ControlSala(IFachadaSala fachada) {
        this.fachada = fachada;
    }


    public ControlSala() {
        this(FabricaSala.crearFachada());
    }

    public JugadorDTO registrarJugador(String nombre, ColorFicha color, int avatar) throws SalaException {
        JugadorDTO registrado = fachada.registrarJugador(new JugadorDTO(nombre, color, avatar));
        registradosAqui.add(registrado);
        return registrado;
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

    /**
     * Revisa si un jugador registrado en esta computadora salió de la sala porque en otra
     * computadora se registró antes alguien con el mismo nombre o color (en P2P gana el
     * registro más antiguo). A cada jugador se le avisa una sola vez.
     *
     * @return un aviso por cada jugador que salió, con el motivo del flujo alterno (A2 o A3)
     */
    public List<SalaException> registrosPerdidos() {
        List<JugadorDTO> enSala = fachada.obtenerJugadores();
        List<SalaException> avisos = new ArrayList<>();
        for (JugadorDTO mio : registradosAqui) {
            if (enSala.contains(mio)) {
                yaAvisados.remove(mio);
            } else if (yaAvisados.add(mio)) {
                avisos.add(motivoDeSalida(mio, enSala));
            }
        }
        return avisos;
    }

    private static SalaException motivoDeSalida(JugadorDTO mio, List<JugadorDTO> enSala) {
        String nombre = "\"" + mio.getNombre() + "\"";
        if (enSala.stream().anyMatch(j -> j.getNombre().equalsIgnoreCase(mio.getNombre()))) {
            return new SalaException(Motivo.NOMBRE_REPETIDO, nombre + " salió de la sala: en otra computadora"
                    + " se registró ese nombre antes. Regístrate con otro nombre.");
        }
        if (enSala.stream().anyMatch(j -> j.getColor() == mio.getColor())) {
            return new SalaException(Motivo.COLOR_OCUPADO, nombre + " salió de la sala: en otra computadora"
                    + " se registró el color " + mio.getColor() + " antes. Regístrate con otro color.");
        }
        return new SalaException(Motivo.SALA_LLENA, nombre + " salió de la sala: se llenó con jugadores"
                + " que se registraron antes en otras computadoras.");
    }
}
