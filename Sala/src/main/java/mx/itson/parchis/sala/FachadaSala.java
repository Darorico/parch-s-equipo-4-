package mx.itson.parchis.sala;

import java.io.IOException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;
import mx.itson.parchis.bos.PerfilBO;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.interfaces.SalaException;
import mx.itson.parchis.interfaces.SalaException.Motivo;

/**
 * Implementación real del subsistema Sala (CU-01 Registrar jugador).
 *
 * Las reglas de la sala (A1, A2, A3) se revisan en memoria con la entidad Sala.
 * Si el registro es válido, el perfil del jugador se guarda en MySQL con PerfilBO
 * y después el jugador entra a la sala. Si guardar el perfil falla, la sala no cambia.
 *
 * Los métodos son synchronized porque la comunicación P2P puede registrar jugadores
 * desde otro hilo al mismo tiempo que la pantalla.
 */
public class FachadaSala implements IFachadaSala {

    /** Mismo límite que la columna nombre de la tabla perfil. */
    static final int NOMBRE_MAX = 50;

    private final Sala sala = new Sala();
    private final PerfilBO perfilBO;
    /** Identifica a esta computadora en los registros que salen de aquí. */
    private final String idPeer = UUID.randomUUID().toString().substring(0, 8);
    /** Conexión con los demás peers; null mientras la sala funciona sin red. */
    private SincronizadorSala red;

    /** Usa el PerfilBO con PerfilDAOMySQL (lee Config/config.properties). */
    public FachadaSala() {
        this(new PerfilBO());
    }

    public FachadaSala(PerfilBO perfilBO) {
        this.perfilBO = perfilBO;
    }

    /**
     * {@inheritDoc}
     *
     * @throws IllegalStateException si no se pudo guardar el perfil en la base de datos
     */
    @Override
    public synchronized JugadorDTO registrarJugador(JugadorDTO jugador) throws SalaException {
        validarDatos(jugador);
        String nombre = jugador.getNombre().trim();

        // A3: ya no cabe nadie
        if (sala.estaLlena()) {
            throw new SalaException(Motivo.SALA_LLENA,
                    "La sala ya está llena (" + MAX_JUGADORES + " jugadores).");
        }
        // A2: el nombre ya lo usa otro jugador
        if (!sala.nombreDisponible(nombre)) {
            throw new SalaException(Motivo.NOMBRE_REPETIDO,
                    "El nombre \"" + nombre + "\" ya está en uso. Elige otro.");
        }
        // A3: el color ya lo usa otro jugador
        if (!sala.colorDisponible(jugador.getColor())) {
            throw new SalaException(Motivo.COLOR_OCUPADO,
                    "El color " + jugador.getColor() + " ya está ocupado. Elige otro.");
        }

        // La hora va en milisegundos porque así viaja por la red: todos los peers ven la misma.
        Jugador nuevo = new Jugador(nombre, jugador.getColor(), jugador.getAvatar(),
                Instant.now().truncatedTo(ChronoUnit.MILLIS), idPeer);
        guardarPerfil(nuevo.aDTO());
        // Siempre entra: ya se revisó que su nombre y color estén libres y que haya lugar.
        sala.agregarJugador(nuevo);
        if (red != null) {
            red.difundirLocal(nuevo);
        }
        return nuevo.aDTO();
    }

    /**
     * Conecta esta sala con los demás peers (estilo P2P). Desde aquí, cada registro
     * se difunde a los otros peers y los registros de ellos llegan a esta sala.
     * Sin llamar a este método, la sala funciona sola, sin red.
     *
     * @param puerto puerto donde escucha este peer
     * @param peers otros peers, con el formato ip:puerto
     * @throws IOException si no se pudo abrir el puerto
     */
    public synchronized void conectarRed(int puerto, List<String> peers) throws IOException {
        if (red != null) {
            throw new IllegalStateException("La sala ya está conectada a la red.");
        }
        SincronizadorSala nueva = new SincronizadorSala(this, idPeer);
        // Los registros hechos antes de conectarse también se comparten con los demás peers.
        nueva.conocer(sala.getSolicitudes());
        nueva.iniciar(puerto, peers);
        red = nueva;
    }

    /**
     * Aplica el registro de un jugador que se registró en otro peer, con la regla
     * "gana el registro más antiguo" (ver Sala). Si choca con un jugador de esta sala,
     * se queda el que se registró primero, aunque el que sale sea de esta computadora.
     * Su perfil no se guarda aquí: cada computadora guarda el perfil de su propio jugador.
     *
     * @return true si el jugador entró a la sala
     */
    synchronized boolean aplicarRegistroRemoto(RegistroRed registro) {
        return sala.agregarJugador(new Jugador(registro.nombre(), registro.color(), registro.avatar(),
                Instant.ofEpochMilli(registro.milisegundos()), registro.origen()));
    }

    /** Puerto donde escucha este peer (para las pruebas). */
    synchronized int getPuertoRed() {
        return red.getPuerto();
    }

    /** Cierra las conexiones con los demás peers (para las pruebas). */
    synchronized void desconectarRed() {
        if (red != null) {
            red.detener();
            red = null;
        }
    }

    @Override
    public synchronized List<JugadorDTO> obtenerJugadores() {
        return sala.getJugadores().stream().map(Jugador::aDTO).toList();
    }

    /** A1: falta el nombre o el color, o no cumplen lo que acepta la tabla perfil. */
    private void validarDatos(JugadorDTO jugador) throws SalaException {
        if (jugador == null || jugador.getNombre() == null || jugador.getNombre().isBlank()
                || jugador.getColor() == null) {
            throw new SalaException(Motivo.DATOS_INCOMPLETOS, "Escribe tu nombre y elige un color.");
        }
        if (jugador.getNombre().trim().length() > NOMBRE_MAX) {
            throw new SalaException(Motivo.DATOS_INCOMPLETOS,
                    "El nombre puede tener máximo " + NOMBRE_MAX + " caracteres.");
        }
        if (jugador.getAvatar() < 0) {
            throw new SalaException(Motivo.DATOS_INCOMPLETOS, "Elige un avatar.");
        }
    }

    /**
     * El perfil es del jugador, no de la sala: si ya jugó antes con ese nombre,
     * se actualizan su color y avatar en lugar de rechazarlo.
     */
    private void guardarPerfil(JugadorDTO perfil) {
        if (perfilBO.obtenerPorNombre(perfil.getNombre()) == null) {
            try {
                perfilBO.registrar(perfil);
                return;
            } catch (RuntimeException e) {
                // Otro peer que usa la misma base de datos insertó ese perfil justo entre la
                // consulta y el insert: ya existe, así que se actualiza. Si no existe, el error es otro.
                if (perfilBO.obtenerPorNombre(perfil.getNombre()) == null) {
                    throw e;
                }
            }
        }
        perfilBO.actualizar(perfil);
    }
}
