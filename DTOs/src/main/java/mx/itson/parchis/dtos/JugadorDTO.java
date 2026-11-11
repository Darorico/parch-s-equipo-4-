package mx.itson.parchis.dtos;

import java.util.Objects;

/**
 * Datos de un jugador que viajan de la presentación al subsistema Sala y de regreso.
 * Es inmutable: no tiene lógica de negocio, solo datos.
 */
public class JugadorDTO {

    private final String nombre;
    private final ColorFicha color;
    private final int avatar;

    public JugadorDTO(String nombre, ColorFicha color, int avatar) {
        this.nombre = nombre;
        this.color = color;
        this.avatar = avatar;
    }

    public String getNombre() {
        return nombre;
    }

    public ColorFicha getColor() {
        return color;
    }

    public int getAvatar() {
        return avatar;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof JugadorDTO otro)) {
            return false;
        }
        return avatar == otro.avatar && Objects.equals(nombre, otro.nombre) && color == otro.color;
    }

    @Override
    public int hashCode() {
        return Objects.hash(nombre, color, avatar);
    }

    @Override
    public String toString() {
        return nombre + " (" + color + ", avatar " + avatar + ")";
    }
}
