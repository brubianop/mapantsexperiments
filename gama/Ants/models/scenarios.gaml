/**
* Name: scenarios
* Based on the internal empty template. 
* Author: Arles
* Tags: 
*/


model scenarios


/* Insert your model definition here */

global {
    // Acción base para mapear coordenadas
    action add_f_point(float nl_x, float nl_y, float amount) {
    	
    	
        int gama_x <- int(50 + (nl_x * 49));
        int gama_y <- int(50 - (nl_y * 49));
        
        gama_x <- max(0, min(99, gama_x));
        gama_y <- max(0, min(99, gama_y));
        
        // Asumimos que el grid se llama 'cells' en el archivo principal
        
        ask cells[gama_x, gama_y] {
            food <- amount;
        }
    }

    // --- ESCENARIOS ---
    action set_one_point_north { do add_f_point(0.0, 1.0, 10.0); }
    
    action set_cross {
        do add_f_point(-1.0, 0.0, 10.0);
        do add_f_point(0.0, -1.0, 10.0);
        do add_f_point(1.0, 0.0, 10.0);
        do add_f_point(0.0, 1.0, 10.0);
        
        
    }
    
    action set_circle {
        int num_points <- 12;
        loop i from: 0 to: num_points - 1 {
            float angle <- (i * 360 / num_points);
            do add_f_point(cos(angle), sin(angle), 10.0);
        }
    }
    
    
    action set_xcross {
        // En NetLogo: add-f-point -1.0 / 2 1.0 / 2 10 / 2
        // Traducido: X=-0.5, Y=0.5, Amount=5.0
        do add_f_point(-1.0, 1.0, 10.0);
        do add_f_point(1.0, -1.0, 10.0);
        do add_f_point(-1.0, -1.0, 10.0);
        do add_f_point(1.0, 1.0, 10.0);
    }
    
    // Puedes seguir agregando todos tus 'to set-...' de NetLogo aquí
}