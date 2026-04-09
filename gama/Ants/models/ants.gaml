/**
* Name: ants
* Based on the internal empty template. 
* Author: Arles
* Tags: 
*/


model ants

//import "antsdiffdynamicgrid.gaml"

/* Insert your model definition here */

global{
	// Definimos la variable global aquí para que sea visible por las hormigas
    // "Uphill": Sube por el gradiente más alto.
    // "Probabilistic": Elige vecino proporcional a la intensidad del olor.
    // "Random": Movimiento aleatorio (ciego).
    string movement_alg <- "uphill" among: ["uphill", "orthogonal", "probabilistic", "random"];	
}

species ant skills: [moving] {
    bool has_food <- false;
    bool active <- false; 
    
    int start_cycle <- 0;
    int time_to_food <- 0;
    
    
    // Al activarse, grabamos el ciclo de inicio
    reflex start_timer when: active and start_cycle = 0 {
        start_cycle <- cycle;
    }
    
    // El agente detecta la celda sobre la que está parado
    // 'cells' debe estar definido en el modelo que importe este archivo
    cells my_cell <- one_of(cells) update: cells(location);
	
    reflex search_food when: !has_food {    	
    	if (!active){
    		return;
    	}
    	// Si la hormiga está fuera de la grilla (my_cell es nil), 
        // forzamos que vuelva a entrar o saltamos el turno para evitar el crash.
        if (my_cell = nil) {
            do wander; // Intentar moverse para volver a entrar
            return;    // Detener la ejecución de este reflex por este ciclo
        }
    	
    	if (movement_alg = "random"){ //random movement
    		do wander amplitude: 90.0;    		
    	}else if (movement_alg = "uphill"){  // Algoritmo Uphill (hacia el olor de comida)    	
        	cells next_step <- my_cell.neighbors with_max_of (each.chemical);        
	        if (next_step != nil and next_step.chemical > 0.05) {
	            do goto target: next_step;
	        } else {
	            do wander amplitude: 45.0; // Exploración si no hay olor
	        }
		}else if(movement_alg = "probabilistic"){
			list<cells> valid_neighbors <- my_cell.neighbors where (each != nil);
			if (empty(valid_neighbors)) {
                do wander amplitude: 45.0;
            }else{
				list<float> smells <- valid_neighbors collect (each.chemical);
				
				if(sum(smells) < 0.1){
					do wander amplitude: 45.0;
				}else{
					int selected_index <- rnd_choice(smells);
					cells next_step <- my_cell.neighbors[selected_index];
					do goto target: next_step;
				}				
			}
			
		}else if(movement_alg = "orthogonal"){
			cells M <- my_cell.neighbors with_max_of (each.chemical);
        	if (M = nil) { do wander; return; }
        	float sensor_angle <- 60.0; //because grid is hexagonal
        	list<point> sensor_points <- get_sensor_coordinates(location, M.location, sensor_angle);
        
        	if (empty(sensor_points)) { do wander; return; }
	        // Recuperamos las celdas en esos puntos
	        cells patch_left <- cells(sensor_points[0]);
	        cells patch_right <- cells(sensor_points[1]);
	        
	        // --- PASO 3: OBTENER VALORES QUÍMICOS ---
        	// Usamos operador ternario: si la celda es nil (fuera de mapa), valor es -1.0
        	float ch_max <- M.chemical;
        	float ch_left <- (patch_left != nil) ? patch_left.chemical : -1.0;
        	float ch_right <- (patch_right != nil) ? patch_right.chemical : -1.0;
        	
        	cells target_cell <- nil;

	        // A. Si M es mejor o igual a los lados, seguimos a M (inercia)
	        if (ch_max >= ch_left and ch_max >= ch_right) {
	            target_cell <- M;
	        }
	        // B. Si la Izquierda es mejor que la Derecha y que M -> Girar Izquierda
	        else if (ch_left >= ch_right and ch_left >= ch_max) {
	            target_cell <- patch_left;
	        }
	        // C. Si la Derecha es mejor que la Izquierda y que M -> Girar Derecha
	        else if (ch_right >= ch_left and ch_right >= ch_max) {
	            target_cell <- patch_right;
	        }
	        // Fallback
	        else {
	            target_cell <- M;
	        }
	        
	       do goto target: target_cell;
		}
		cells new_patch <- cells(location);
		if (new_patch != nil) {
	        	
	        
	            // Verificar si encontramos comida
	            if (new_patch.food > 0) {
	                has_food <- true;
	                
	                if(start_cycle != 0){
				        // Calculamos el tiempo de este viaje específico			        		           
			            int trip_duration <- cycle - start_cycle;
			            
			            // Enviamos el dato al global
			            ask world { 
			                do register_success(trip_duration); 
			            }
			            
			            // Ponemos el cronómetro en -1 para indicar que el viaje de "ida" terminó
			            start_cycle <- -1;			           
		            }
	                
	                heading <- heading + 180; // Darse la vuelta
	                
	                // Opcional: Consumir comida
	                // target_cell.food <- target_cell.food - 1.0;
	            }
	    	} else {
	        // Si el target calculado era inválido (borde del mapa), vagar
	        	do wander;
	    }
				
        if (my_cell.food > 0) { //validación de comida para cambiar de estado
            has_food <- true;
        }
    }

    reflex go_home when: active and has_food {
        // Algoritmo Uphill (hacia el gradiente del nido)
        // 1. ACTUALIZACIÓN CRÍTICA: Obtener la celda donde estoy parado AHORA
        cells my_current_cell <- cells(location);
        
        // 2. SEGURIDAD: Si por algún motivo estoy fuera del mapa
        if (my_current_cell = nil) {
            do wander; 
            return; 
        }
        
        list<cells> valid_neighbors <- my_cell.neighbors where (each != nil);
		if (empty(valid_neighbors)) {
            do wander amplitude: 45.0;
        }else {                
	        cells next_step <- valid_neighbors with_max_of (each.nest_scent);
	        
	        if (next_step != nil) {
	            do goto target: next_step;
	        }	
		}
        if (my_cell.is_nest) {
        	start_cycle <- cycle;
            has_food <- false;
        }
    }

    aspect default {
        // Si no están activas, se ven grises (dormidas). Si se activan, cambian de color.
        if (!active) {
            draw circle(0.5) color: #gray; 
        } else {
            draw circle(0.5) color: has_food ? #orange : #white;
        }
    }
    
   // -----------------------------------------------------------------------
    // FUNCIÓN AUXILIAR: CALCULAR PUNTOS SENSORALES
    // Devuelve los puntos a la izquierda y derecha del vector de movimiento
    // -----------------------------------------------------------------------
    list<point> get_sensor_coordinates(point origin, point target, float angle) {
        // 1. Vector dirección hacia el vecino con más olor (M)
        point direction <- target - origin;
        
        // 2. Rotamos el vector (GAMA lo hace automáticamente)
        // -angle para izquierda, +angle para derecha
        point vec_left <- direction rotated_by -angle;
        point vec_right <- direction rotated_by angle;
        
        // 3. Calculamos los puntos finales absolutos
        point pt_left <- origin + vec_left;
        point pt_right <- origin + vec_right;
        
        return [pt_left, pt_right];
    }
}