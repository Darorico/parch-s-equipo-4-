package mx.itson.parchis.presentacion.pantallas;

import java.awt.Color;
import java.util.List;
import java.util.stream.Collectors;
import javax.swing.DefaultComboBoxModel;
import javax.swing.DefaultListModel;
import javax.swing.SpinnerNumberModel;
import javax.swing.SwingConstants;
import javax.swing.Timer;
import mx.itson.parchis.dtos.ColorFicha;
import mx.itson.parchis.dtos.JugadorDTO;
import mx.itson.parchis.interfaces.IFachadaSala;
import mx.itson.parchis.interfaces.SalaException;
import mx.itson.parchis.presentacion.control.ControlSala;

public class PantallaRegistro extends javax.swing.JFrame {

    private static final java.util.logging.Logger logger = java.util.logging.Logger.getLogger(PantallaRegistro.class.getName());

        private static final int NUM_AVATARES = 6;

        /** Cada cuánto se revisa si llegaron jugadores de otras computadoras (P2P). */
        private static final int REVISION_MS = 500;

        private final ControlSala control;
        private final DefaultListModel<String> modeloJugadores = new DefaultListModel<>();
        /** Jugadores que se ven ahora en la lista. */
        private List<JugadorDTO> mostrados = List.of();
        /** Revisa la sala en el hilo de Swing, así la pantalla se actualiza sola. */
        private final Timer revision = new Timer(REVISION_MS, e -> revisarSala());

        public PantallaRegistro(ControlSala control) {
                this.control = control;
                initComponents();
                configurarComponentes();
                refrescarJugadores();
                revision.start();
            }

        /** Ajustes que no se hacen en el disenador */
        private void configurarComponentes() {
            setTitle("Parchis en red - Registro de jugador");
            setDefaultCloseOperation(EXIT_ON_CLOSE);
            setLocationRelativeTo(null);

            ColorFicha[] colores = ColorFicha.values();
            String[] nombres = new String[colores.length];
            for (int i = 0; i < colores.length; i++) {
                nombres[i] = colores[i].name();
            }
            cmbColor.setModel(new DefaultComboBoxModel<>(nombres));

            spinnerAvatar.setModel(new SpinnerNumberModel(0, 0, NUM_AVATARES - 1, 1));
            listJugadores.setModel(modeloJugadores);

            lblError.setForeground(Color.RED);
            lblError.setVerticalAlignment(SwingConstants.TOP);
            lblError.setText(" ");
            getRootPane().setDefaultButton(btnRegistrar);
        }

        /** Manejador del boton Registrar */
        private void alRegistrar() {
            try {
                ColorFicha color = ColorFicha.valueOf((String) cmbColor.getSelectedItem());
                int avatar = (Integer) spinnerAvatar.getValue();

                control.registrarJugador(txtNombre.getText(), color, avatar);

                lblError.setText(" ");
                txtNombre.setText("");
                refrescarJugadores();
                txtNombre.requestFocusInWindow();
            } catch (SalaException ex) {
                mostrarError(ex.getMessage());
                switch (ex.getMotivo()) {
                    case DATOS_INCOMPLETOS, NOMBRE_REPETIDO -> txtNombre.requestFocusInWindow();
                    case COLOR_OCUPADO -> cmbColor.requestFocusInWindow();
                    case SALA_LLENA -> btnRegistrar.setEnabled(false);
                }
                refrescarJugadores();
            }
        }

        /** Muestra el mensaje completo: con HTML el texto largo baja de renglon en vez de cortarse. */
        private void mostrarError(String mensaje) {
            String seguro = mensaje.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                    .replace("\n", "<br>");
            lblError.setText("<html>" + seguro + "</html>");
        }

        /**
         * Lo hace el Timer cada medio segundo: si llegó o salió alguien desde otra computadora,
         * refresca la lista; si un jugador de esta computadora perdió su lugar contra un registro
         * más antiguo, lo avisa con el mensaje de A2 (nombre) o A3 (color).
         */
        private void revisarSala() {
            if (!control.obtenerJugadores().equals(mostrados)) {
                refrescarJugadores();
            }
            List<SalaException> avisos = control.registrosPerdidos();
            if (!avisos.isEmpty()) {
                mostrarError(avisos.stream().map(SalaException::getMessage).collect(Collectors.joining("\n")));
            }
        }

        private void refrescarJugadores() {
            mostrados = control.obtenerJugadores();
            modeloJugadores.clear();
            for (JugadorDTO j : mostrados) {
                modeloJugadores.addElement(j.getNombre() + "  -  " + j.getColor() + "  -  avatar " + j.getAvatar());
            }
            lblContador.setText("Jugadores registrados: " + modeloJugadores.size()
                    + " / " + IFachadaSala.MAX_JUGADORES);

            // Se respeta el color que eligió el usuario mientras siga libre; si no, el primero libre.
            var libres = control.coloresDisponibles();
            String elegido = (String) cmbColor.getSelectedItem();
            if (!libres.isEmpty() && libres.stream().noneMatch(c -> c.name().equals(elegido))) {
                cmbColor.setSelectedItem(libres.get(0).name());
            }
            // Si alguien salió de la sala y ya hay lugar, se puede volver a registrar.
            if (!control.salaLlena()) {
                btnRegistrar.setEnabled(true);
            }
        }


    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        lblNombre = new javax.swing.JLabel();
        txtNombre = new javax.swing.JTextField();
        lblColor = new javax.swing.JLabel();
        cmbColor = new javax.swing.JComboBox<>();
        lblAvatar = new javax.swing.JLabel();
        spinnerAvatar = new javax.swing.JSpinner();
        btnRegistrar = new javax.swing.JButton();
        lblError = new javax.swing.JLabel();
        lblContador = new javax.swing.JLabel();
        jScrollPane1 = new javax.swing.JScrollPane();
        listJugadores = new javax.swing.JList<>();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);

        lblNombre.setText("Nombre:");

        txtNombre.addActionListener(this::txtNombreActionPerformed);

        lblColor.setText("Color:");

        cmbColor.setModel(new javax.swing.DefaultComboBoxModel<>(new String[] { "Item 1", "Item 2", "Item 3", "Item 4" }));

        lblAvatar.setText("Avatar (0 a 5):");

        btnRegistrar.setText("Registrar");
        btnRegistrar.addActionListener(this::btnRegistrarActionPerformed);

        lblContador.setText("Jugadores registrados: 0 / 4");

        listJugadores.setModel(new javax.swing.AbstractListModel<String>() {
            String[] strings = { "Item 1", "Item 2", "Item 3", "Item 4", "Item 5" };
            public int getSize() { return strings.length; }
            public String getElementAt(int i) { return strings[i]; }
        });
        jScrollPane1.setViewportView(listJugadores);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(lblNombre)
                            .addComponent(lblColor)
                            .addComponent(lblAvatar))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(txtNombre, javax.swing.GroupLayout.DEFAULT_SIZE, 320, Short.MAX_VALUE)
                            .addComponent(cmbColor, javax.swing.GroupLayout.PREFERRED_SIZE, 140, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(spinnerAvatar, javax.swing.GroupLayout.PREFERRED_SIZE, 60, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(btnRegistrar)))
                    .addComponent(lblError, 0, 420, Short.MAX_VALUE)
                    .addComponent(lblContador, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 420, Short.MAX_VALUE))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(lblNombre)
                    .addComponent(txtNombre, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(lblColor)
                    .addComponent(cmbColor, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(lblAvatar)
                    .addComponent(spinnerAvatar, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(btnRegistrar)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(lblError, javax.swing.GroupLayout.PREFERRED_SIZE, 36, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(lblContador)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 130, Short.MAX_VALUE)
                .addContainerGap())
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void txtNombreActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_txtNombreActionPerformed
        // TODO add your handling code here:
    }//GEN-LAST:event_txtNombreActionPerformed

    private void btnRegistrarActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_btnRegistrarActionPerformed
         alRegistrar();
    }//GEN-LAST:event_btnRegistrarActionPerformed



    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton btnRegistrar;
    private javax.swing.JComboBox<String> cmbColor;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JLabel lblAvatar;
    private javax.swing.JLabel lblColor;
    private javax.swing.JLabel lblContador;
    private javax.swing.JLabel lblError;
    private javax.swing.JLabel lblNombre;
    private javax.swing.JList<String> listJugadores;
    private javax.swing.JSpinner spinnerAvatar;
    private javax.swing.JTextField txtNombre;
    // End of variables declaration//GEN-END:variables
}
