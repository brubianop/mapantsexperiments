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
        int gama_x <- int(50 + (nl_x * 40));
        int gama_y <- int(50 - (nl_y * 40));
        
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
    
    action set_isotropic_food_four{
    	do 	set_isotropic_food(4, 40.0);
    }
    
    action set_isotropic_food (int num_sources, float radius) {
    // Definimos el centro (donde está tu nido)
    point center <- {50.0, 50.0};
    
    // Repartimos los puntos equitativamente en 360 grados
    loop i from: 0 to: num_sources - 1 {
        // Calculamos el ángulo para este punto de comida
        float angle <- i * (360.0 / num_sources);
        
        // Calculamos la coordenada X y Y exactas en el espacio continuo
        float target_x <- center.x + (radius * cos(angle));
        float target_y <- center.y + (radius * sin(angle));
        point food_location <- {target_x, target_y};
        
        // Magia de GAMA: Le pedimos a la celda que contiene ese punto físico que se active
        ask cells(food_location) {
            food <- 10.0;
        	}
    	}
	}
    
    

	action set_one_point_hex_ang (int angle, float radius) {
    	// 1. Usamos el centro geométrico EXACTO de la celda central
    	point center <- cells[50, 50].location;
            
        // 2. Calculamos la coordenada destino en el espacio continuo
        float target_x <- center.x + (radius * cos(angle));
        float target_y <- center.y + (radius * sin(angle));
        point food_location <- {target_x, target_y};
        
        // 3. MAGIA: 'closest_to' ignora si el punto cae en un borde ambiguo.
        // Calcula qué centro de hexágono está más cerca de tu objetivo matemático.
        ask cells closest_to(food_location) {
            food <- 10.0;
        }
    }
	
	
	action set_one_point_hex_angle {     	
     	do set_one_point_hex_ang(0, 30.0);
    }
    
    action set_two_points_hex_angle {     	
     	do set_one_point_hex_ang(0, 30.0);
     	do set_one_point_hex_ang(180, 30.0);
    }
    
    //Center point. Diffusion purposes.
    action set_one_point_center {
    	do add_f_point(0.0, 0.0, 10.0);
    }
    
    //Diagonal points.
    action set_diagonal {
    	do add_f_point(1.0, 1.0, 10.0);
    	do add_f_point(-1.0, -1.0, 10.0);
    }
    
    //Orthogonal and diagonal
    action set_ortho_diag {
    	do add_f_point(1.0, 0.0, 10.0);
    	do add_f_point(1.0, -1.0, 10.0);
    }
    
    
    
    // Puedes seguir agregando todos tus 'to set-...' de NetLogo aquí
}