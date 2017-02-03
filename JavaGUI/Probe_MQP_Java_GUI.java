/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package probe_mqp_java_gui;

import javax.swing.UIManager;

/**
 *
 * @author motmo
 */
public class Probe_MQP_Java_GUI {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
                try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        }catch(Exception ex) {
            ex.printStackTrace();
        }
       MainUIJFrame main_ui = new MainUIJFrame();
       main_ui.setVisible(true);
    }
    
}
