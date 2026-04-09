/**
* Name: Scent Diffusion Model
* Author: [Your Name / Team]
* Description: Simulates the emission of a chemical scent from food sources, 
* its diffusion through the environment, and its evaporation over time.
*/

model ScentDiffusion

global {
    // -----------------------------------------------------------------
    // PHYSICAL PARAMETERS
    // -----------------------------------------------------------------
    
    // Controls how fast the scent spreads to neighbors (0.0 to 1.0)
    float diffusion_rate <- 0.8 min: 0.0 max: 1.0;
    
    // Controls how fast the scent disappears from the environment (0.0 to 1.0)
    // Low values (e.g., 0.005) allow the scent to travel further.
    float evaporation_rate <- 0.005 min: 0.0 max: 1.0; 
    
    // Grid dimensions
    int grid_size <- 50; 
    geometry shape <- square(grid_size);

    // -----------------------------------------------------------------
    // INITIALIZATION
    // -----------------------------------------------------------------
    init {
        write "Initializing simulation environment...";
        
        // Place food sources at specific coordinates [x, y]
        // Scenario: Two sources with different sizes (intensities)
        
        // Standard food source (Size 1.0) at center
        ask cells[25, 25] { 
            food <- 1.0; 
        } 
        
        // Large food source (Size 2.0) at the bottom-left
        // This source will emit a stronger scent.
        ask cells[10, 10] { 
            food <- 20.0; 
        } 
    }

    // -----------------------------------------------------------------
    // MAIN PHYSICS LOOP (Executed every cycle)
    // -----------------------------------------------------------------
    reflex diffusion_dynamics {
        
        // STEP 1: EMISSION (Source)
        // Food sources constantly emit chemical into their current cell.
        // The emission is proportional to the food amount (size).
        ask cells where (each.food > 0) {
            // We multiply by 100.0 to create a strong concentration gradient
            chemical <- food * 100.0; 
        }
        
        // STEP 2: DIFFUSION (Spread)
        // GAMA's optimized algorithm spreads the 'chemical' variable 
        // from cells with high values to neighbors with low values.
        diffuse var: chemical on: cells proportion: diffusion_rate;

        // STEP 3: EVAPORATION (Decay)
        // The scent dissipates over time to prevent infinite accumulation.
        ask cells {
            chemical <- chemical * (1 - evaporation_rate);
        }
    }
} 

// -----------------------------------------------------------------
// GRID ENVIRONMENT (The Patches)
// -----------------------------------------------------------------
grid cells width: grid_size height: grid_size neighbors: 8 {
    // State variables
    float chemical <- 0.0;  // The scent intensity
    float food <- 0.0;      // Amount of food (0 if empty)

    // -----------------------------------------------------------------
    // VISUALIZATION LOGIC (Heatmap)
    // -----------------------------------------------------------------
    // 'update' forces the color to be recalculated every simulation step.
    rgb color <- #black update: calculate_color();
    
  
   // Helper action to determine cell color based on state
    rgb calculate_color {
        // --- NUEVO: Condición para resaltar la celda específica ---
        if (grid_x = 12 and grid_y = 12) {
            return #yellow;
        }
        // ----------------------------------------------------------

        if (food > 0) {
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

// -----------------------------------------------------------------
// EXPERIMENT / GUI
// -----------------------------------------------------------------
experiment MainExperiment type: gui {
    
    // Define inputs accessible via the UI
    // The 'parameter' keyword connects the UI slider to the global variable
    parameter "Diffusion Speed" var: diffusion_rate;
    parameter "Evaporation Speed" var: evaporation_rate;

    output {
        // Main Map Display
        // Background is dark gray to ensure contrast with the black grid
        display "Environment" background: rgb(20, 20, 20) {
            grid cells;
        }
        
        // Optional: Chart to track total chemical amount in the system
        /*display "Statistics" {
            chart "Total Scent in Air" type: series {
                data "Sum of Chemical" value: sum(cells collect each.chemical) color: #cyan;
            }
        }*/
        display "Grafica del Centro" {
            chart "Smell at [12,12]" type: series {
                data "Intensidad" value: cells[12,12].chemical color: #yellow;
            }
        }
        
        // Monitor numérico para ver el valor exacto
        monitor "Valor Exacto en [12,12]" value: cells[12,12].chemical;
    }
}