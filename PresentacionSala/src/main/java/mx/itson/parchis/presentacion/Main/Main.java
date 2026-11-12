package mx.itson.parchis.presentacion.Main;

import javax.swing.SwingUtilities;
import mx.itson.parchis.presentacion.control.ControlSala;
import mx.itson.parchis.presentacion.pantallas.PantallaRegistro;


public class Main {

    public static void main(String[] args) {
        // Una sola instancia de ControlSala para toda la aplicación
        ControlSala control = new ControlSala();
        SwingUtilities.invokeLater(() -> new PantallaRegistro(control).setVisible(true));
    }
}