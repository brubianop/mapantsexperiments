/**
* Name: antsdiffdynamic
* Based on the internal empty template. 
* Author: Arles
* Tags: 
*/


model antsdiffdynamicgrid

/* Insert your model definition here */

import "scenarios.gaml"
import "ants.gaml"

global {
	//Diffusion Model Switch
	string diffusion_mode <- "Standard" among: ["Standard", "Gaussian", "Gaussian-Weighted"];
	
    // -----------------------------------------------------------------
    // PHYSICAL PARAMETERS
    // -----------------------------------------------------------------
    
    
    // Controls how fast the scent spreads to neighbors (0.0 to 1.0)
    float diffusion_rate <- 0.8 min: 0.0 max: 1.0;
    
    // Controls how fast the scent disappears from the environment (0.0 to 1.0)
    // Low values (e.g., 0.005) allow the scent to travel further.
    float evaporation_rate <- 0.0 min: 0.0 max: 1.0; 
   
   
    // Grid dimensions
    int grid_size <- 100;
    
    
    // ronda máxima de difusión
    int diffusion_rounds <- 200;
     
	// List to save travel times
	list<int> travel_times <- [];
	
	//average times
	float avg_travel_time <- 0.0 update: (empty(travel_times)) ? 0.0 : mean(travel_times);     
	
	//register time
	action register_success(int t){
		add t to: travel_times;
	}
	
	

	
     
    geometry shape <- square(grid_size);
    
    int ants_number <- 30;
    
	// Parámetro para elegir el escenario desde la interfaz
    string scenario_type <- "Cross" among: ["North", "Cross", "Circle", "Xcross", "Center", "Diagonal", "Ortho-Diag"];

    // -----------------------------------------------------------------
    // INITIALIZATION
    // -----------------------------------------------------------------
    init {
    	if (scenario_type = "North") { do set_one_point_north; }
        if (scenario_type = "Cross") { do set_cross; }
        if (scenario_type = "Xcross") { do set_xcross; }
        if (scenario_type = "Circle") { do set_circle; }
        if (scenario_type = "Center") { do set_one_point_center; }
        if (scenario_type = "Diagonal") { do set_diagonal; }
        if (scenario_type = "Ortho-Diag") { do set_ortho_diag; }
        
        
        create nest_point number: 1 {location <- {50, 50};}
        
        create ant number: ants_number {
        	location <- {50, 50};
        	
        }

        /*write "Initializing simulation environment...";
        
        // Place food sources at specific coordinates [x, y]
        // Scenario: Two sources with different sizes (intensities)
        
        // Standard food source (Size 1.0) at center
        ask cells[25, 25] { 
            food <- 10.0; 
        } 
        
        // Large food source (Size 2.0) at the bottom-left
        // This source will emit a stronger scent.
        ask cells[10, 10] { 
            food <- 20.0; 
        } */
        
    }

   reflex diffusion_dynamics {
   	if(cycle <= diffusion_rounds){
    	
        // CAMBIO 1: EMISIÓN ACUMULATIVA
        ask cells where (each.food > 0) {
            // Usamos += para que el olor se sume en cada ciclo en lugar de resetearse
            chemical <- food*10; 
        }
        
        // STEP 2: DIFFUSION
        //diffuse var: chemical on: cells propagation: diffusion proportion: diffusion_rate;
        // 2. DIFUSIÓN MANUAL (Cálculo del promedio de vecinos como en NetLogo)
   		// Usamos 'temp_chemical' para que el cálculo de una celda no afecte a la siguiente en el mismo ciclo
   		if (diffusion_mode = "Standard") {
   			 
   			ask cells {
   				float promedio_vecinos <- neighbors mean_of (each.chemical);
   				new_chemical <- chemical + diffusion_rate * (promedio_vecinos - chemical);
   				}
   				
   		} else if (diffusion_mode = "Gaussian") {
        	ask cells {
            	float p_c <- chemical;
            	// Trick. Conservation of Mass around edges.
            	// 4 center, 2 * 4 orthogonal, 1 * 4 diagonal -> 16
            	float p_sum <- 16 * p_c;
            	loop n over: neighbors {
                	if (n.grid_x = self.grid_x or n.grid_y = self.grid_y) {
                    	p_sum <- p_sum - (2 * p_c) + (2 * n.chemical); //Orthogonal.
                	} else {
                    	p_sum <- p_sum - (1 * p_c) + (1 * n.chemical); //Diagonal.
                	}
            	}
            
            	float p_val <- p_sum / 16;
            	new_chemical <- chemical + diffusion_rate * (p_val - chemical);
        	}
    	} else if (diffusion_mode = "Gaussian-Weighted") {
    		ask cells {
    			float p_sum <- 0.0;
    			int w_sum <- 4;
    			p_sum <- 4 * self.chemical; //Center cell initial weighted val.
    			loop n over: neighbors {
    				if (n.grid_x = self.grid_x or n.grid_y = self.grid_y) {
    					p_sum <- p_sum + (2 * n.chemical);
    					w_sum <- w_sum + 2;
    				} else {
    					p_sum <- p_sum + (1 * n.chemical);
    					w_sum <- w_sum + 1;
    				}
    			}	
    				
    			float p_val <- p_sum / w_sum; //Weighted normalized sum. 
    			new_chemical <- chemical + diffusion_rate * (p_val - chemical);
    		}
    			
    	}
	    
	    ask cells{
	    	chemical <- new_chemical;
		}
		
		// STEP 3: EVAPORATION
        //Redundant IF statement
		if (evaporation_rate > 0) {
			ask cells {
				chemical <- chemical * (1 - evaporation_rate);
		    }
		 }
		  
    }
    // FASE 2: LIBERACIÓN (En el momento exacto que termina la difusión)
        else if (cycle = diffusion_rounds + 1) {
            
            write ">>> ¡DIFUSIÓN COMPLETADA! Liberando hormigas...";
            
            // --- ORDEN DE LIBERACIÓN ---
            ask ant {
                active <- true;
            }
            // ---------------------------
        }
    }
} 

// -----------------------------------------------------------------
// GRID ENVIRONMENT (The Patches)
// -----------------------------------------------------------------
grid cells width: grid_size height: grid_size neighbors: 8 { //to check!
    // State variables
    float chemical <- 0.0;  // The scent intensity
    float new_chemical <- 0.0;  // To store temporal chemical
    float food <- 0.0;      // Amount of food (0 if empty)
    float nest_scent <- 0.0; //smell of nest
	bool is_nest <- false;
	
	init {
        nest_scent <- 200 - (location distance_to {50, 50});
        //if (location distance_to {25, 25} < 1.0) { is_nest <- true; }
        ask cells[50, 50] {
            is_nest <- true;
        }
    }
	
    // -----------------------------------------------------------------
    // VISUALIZATION LOGIC (Heatmap)
    // -----------------------------------------------------------------
    // 'update' forces the color to be recalculated every simulation step.
    rgb color <- #black update: calculate_color();
    
  
   // Helper action to determine cell color based on state
    rgb calculate_color {
    	
    	/*if (self distance_to location({25,25,0}) > 24) {
            return #black;
        }*/
    	
        // --- NUEVO: Condición para resaltar la celda específica ---
        if (grid_x = 17 and grid_y = 17) {
            return #yellow;
        }
        // ----------------------------------------------------------

		if (is_nest){
			return #magenta;
		}
        else if (food > 0) {
            // Food is always RED
            return #red;
        } 
        else if //(chemical > 0.001) {
            // Scent trail visualization
            //return hsb(0.6, 1.0, min(1.0, chemical * 2.0));
        //}
        		(chemical > 0) { 
    		return hsb(0.6, 1.0, min(1.0, chemical * 100.0)); // Multiplicamos por mucho para verlo
		} 
        else {
            // Empty space is BLACK
            return #black;
        }
    }
}

/* ESPECIES */
species nest_point {
    aspect circle { 
        draw circle(3.0) color: #magenta; 
    }
}

// -----------------------------------------------------------------
// EXPERIMENT / GUI
// -----------------------------------------------------------------
experiment MainExperimentNetDiff type: gui {
    
    // Define inputs accessible via the UI
    // The 'parameter' keyword connects the UI slider to the global variable
    parameter "Diffusion Speed" var: diffusion_rate;
    parameter "Evaporation Speed" var: evaporation_rate;
	parameter "Scenario" var: scenario_type;
	parameter "Movement alg:" var: movement_alg;
	parameter "Difussion rounds:" var: diffusion_rounds;
	parameter "Diffusion Mode" var: diffusion_mode;
	
	action export_chemical_map {
        // 1. Definimos la ruta
        string file_path <- "../includes/mapa_" + diffusion_mode + "_" + scenario_type + "_" +cycle + ".csv";
        
        // 2. Creamos una lista que contendrá todas las filas (empezando por el encabezado)
        list<list> data_to_save <- [["grid_x", "grid_y", "chemical_value"]];
        
        // 3. Llenamos la lista en memoria (esto es muy rápido)
        // Usamos 'sort_by' para que el CSV quede ordenado por coordenadas
        loop c over: cells sort_by (each.grid_y * 100 + each.grid_x) {
            add [c.grid_x, c.grid_y, c.chemical] to: data_to_save;
        }
        
        // 4. GUARDADO ÚNICO: Escribimos todo el archivo de una sola vez
        save data_to_save to: file_path;
        
        write ">>> Mapa exportado exitosamente (10,000 celdas) en: " + file_path;
    }
	// Esto crea un botón en el panel de control de la izquierda
    user_command "Exportar Mapa CSV" action: export_chemical_map;
	
    output {
        // Main Map Display
        // Background is dark gray to ensure contrast with the black grid
        display "Environment" background: rgb(20, 20, 20) {
            grid cells;
            species nest_point;
            species ant;
        }
        
        // NUEVO DISPLAY DE ESTADÍSTICAS
        display "Estadísticas de Búsqueda" {
            // Gráfico de barras/histograma de los tiempos registrados
            chart "Distribución de Tiempos de Hallazgo" type: series {
                data "Tiempo de viaje (ciclos)" value: travel_times color: #blue;
            }
            
            // Gráfico del promedio histórico
            chart "Eficiencia Promedio" type: series {
                data "Promedio" value: avg_travel_time color: #red;
            }
        }
        
        // Optional: Chart to track total chemical amount in the system
        /*display "Statistics" {
            chart "Total Scent in Air" type: series {
                data "Sum of Chemical" value: sum(cells collect each.chemical) color: #cyan;
            }
        }*/
        display "Grafica del Centro" {
            chart "Smell at [17,17]" type: series {
                data "Intensidad" value: cells[17,17].chemical color: #yellow;
            }
        }
        
        // Monitor numérico para ver el valor exacto
        monitor "Valor Exacto en [17,17]" value: cells[17,17].chemical;
        monitor "Valor Exacto en [25,25]" value: cells[25,25].chemical;
        monitor "Valor Exacto en [25,26]" value: cells[25,26].chemical;
        monitor "Coordenadas Vecinos [50,30]" value: cells[50,30].neighbors collect [each.grid_x, each.grid_y, each.chemical];
        
        
        // Monitores para lectura rápida
        monitor "Hormigas con éxito" value: length(travel_times);
        monitor "Tiempo Promedio (Ciclos)" value: avg_travel_time;
    }
}