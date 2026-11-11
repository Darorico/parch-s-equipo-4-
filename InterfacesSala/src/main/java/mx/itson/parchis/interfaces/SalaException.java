package mx.itson.parchis.interfaces;

/**
 * Error de negocio del subsistema Sala. Cada motivo corresponde a un flujo alterno del CU-01.
 */
public class SalaException extends Exception {

    /** Flujos alternos del CU-01. */
    public enum Motivo {
        /** A1: falta el nombre o el color. */
        DATOS_INCOMPLETOS,
        /** A2: otro jugador ya usa ese nombre. */
        NOMBRE_REPETIDO,
        /** A3: otro jugador ya usa ese color. */
        COLOR_OCUPADO,
        /** A3: ya hay 4 jugadores en la sala. */
        SALA_LLENA
    }

    private final Motivo motivo;

    public SalaException(Motivo motivo, String mensaje) {
        super(mensaje);
        this.motivo = motivo;
    }

    public Motivo getMotivo() {
        return motivo;
    }
}
