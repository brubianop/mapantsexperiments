import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from matplotlib.collections import PatchCollection
import matplotlib.patheffects as path_effects
import sys
import re

# --- 1. CARGA DE DATOS DE GAMA ---
def load_gama_matrix(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: No se encontró el archivo {filename}")
        return None, None, None, None, None

    matches = re.findall(r'\[(.*?)\]', content)
    
    pxcors, pycors, values = [], [], []

    for match in matches:
        clean_match = match.replace("'", "").replace('"', "").replace(" ", "")
        parts = clean_match.split(',')
        
        if len(parts) < 3 or parts[0] == 'grid_x' or 'source' in parts[0]:
            continue
        
        try:
            pxcors.append(int(parts[0]))
            pycors.append(int(parts[1]))
            values.append(float(parts[2]))
        except ValueError:
            continue

    if not values:
        print("Error: No se pudieron extraer datos válidos del archivo.")
        return None, None, None, None, None

    px = np.array(pxcors)
    py = np.array(pycors)
    vals = np.array(values)

    min_x, max_x = px.min(), px.max()
    min_y, max_y = py.min(), py.max()
    
    cols = max_x - min_x + 1
    rows = max_y - min_y + 1

    grid_data = np.zeros((rows, cols))
    for x, y, v in zip(px, py, vals):
        grid_data[y - min_y, x - min_x] = v

    return grid_data, min_x, max_x, min_y, max_y

# --- 2. FUNCIÓN PRINCIPAL ---
def main():
    if len(sys.argv) < 2:
        print("Uso: python script.py mapa_quimico_xxx.csv")
        sys.exit(1)

    filename = sys.argv[1]
    
    grid_data, min_x, max_x, min_y, max_y = load_gama_matrix(filename)
    
    if grid_data is None:
        sys.exit(1)

    rows, cols = grid_data.shape

    # --- 3. VISUALIZACIÓN RECTANGULAR ---
    fig, ax = plt.subplots(figsize=(12, 10))
    
    patches = []
    width, height = 1.0, 1.0
    text_objects = []
    
    for r in range(rows):
        for c in range(cols):
            x_pos = c * width
            y_pos = r * height
            
            rect = Rectangle((x_pos - width/2, y_pos - height/2), width, height)
            patches.append(rect)
            
            val = grid_data[r, c]
            # Mostrar 3 decimales 
            txt = ax.text(x_pos, y_pos, f"{val:.3f}", ha='center', va='center', 
                          color='white', fontsize=7, visible=False, zorder=5)
            txt.set_path_effects([path_effects.withStroke(linewidth=1.5, foreground='black')])
            text_objects.append((c, r, txt))

    collection = PatchCollection(patches, cmap='viridis', edgecolor='black', linewidth=0.2)
    collection.set_array(grid_data.flatten())
    ax.add_collection(collection)
    
    plt.colorbar(collection, label='Nivel de Chemical', pad=0.02)
    ax.set_aspect('equal')
    
    ax.set_xlim(-width, cols * width)
    ax.set_ylim(-height, rows * height)
    ax.invert_yaxis()

    default_title = f"Matriz de Difusión - {filename}"
    ax.set_title(default_title, pad=20)
    ax.set_xlabel("Eje X Espacial")
    ax.set_ylabel("Eje Y Espacial")

    # --- 4. EVENTOS INTERACTIVOS ---

    # Formateador inferior
    def format_coord(x, y):
        c_approx = int(round(x))
        r_approx = int(round(y))
        if 0 <= r_approx < rows and 0 <= c_approx < cols:
            val = grid_data[r_approx, c_approx]
            # Mostrar 5 decimales en la barra inferior
            return f"X: {min_x + c_approx}, Y: {min_y + r_approx} | Chemical: {val:.5f}"
        return f"X: {x:.2f}, Y: {y:.2f}"
    ax.format_coord = format_coord

    # Hover flotante
    annot = ax.annotate("", xy=(0,0), xytext=(20,20), textcoords="offset points",
                        bbox=dict(boxstyle="round", fc="w", alpha=0.9),
                        arrowprops=dict(arrowstyle="->"), zorder=10)
    annot.set_visible(False)

    def hover(event):
        if event.inaxes == ax:
            c_approx = int(round(event.xdata))
            r_approx = int(round(event.ydata))
            if 0 <= r_approx < rows and 0 <= c_approx < cols:
                val = grid_data[r_approx, c_approx]
                annot.xy = (event.xdata, event.ydata)
                # Mostrar 5 decimales en el globo interactivo
                annot.set_text(f"Grid ({min_x + c_approx}, {min_y + r_approx})\nVal: {val:.5f}")
                annot.set_visible(True)
                fig.canvas.draw_idle()
            else:
                if annot.get_visible():
                    annot.set_visible(False)
                    fig.canvas.draw_idle()
    fig.canvas.mpl_connect("motion_notify_event", hover)

    # Zoom: Mostrar valores al acercarse
    def on_zoom_change(*args):
        xlim = ax.get_xlim()
        ylim = ax.get_ylim()
        
        y_min, y_max = min(ylim), max(ylim)
        x_min, x_max = min(xlim), max(xlim)

        zoom_threshold = 25
        if (x_max - x_min) < zoom_threshold and (y_max - y_min) < zoom_threshold:
            for c, r, txt in text_objects:
                if x_min <= c <= x_max and y_min <= r <= y_max:
                    txt.set_visible(True)
                else:
                    txt.set_visible(False)
        else:
            for c, r, txt in text_objects:
                txt.set_visible(False)
        fig.canvas.draw_idle()

    ax.callbacks.connect('xlim_changed', on_zoom_change)
    ax.callbacks.connect('ylim_changed', on_zoom_change)

    # Click: Máximo en vecindad y resaltes múltiples
    highlight_patches = [] 

    def on_click(event):
        if event.inaxes != ax:
            return
            
        c_approx = int(round(event.xdata))
        r_approx = int(round(event.ydata))

        if 0 <= r_approx < rows and 0 <= c_approx < cols:
            max_val = -float('inf')
            max_r, max_c = r_approx, c_approx

            # Vecindad 3x3 (Moore)
            for i in range(max(0, r_approx - 1), min(rows, r_approx + 2)):
                for j in range(max(0, c_approx - 1), min(cols, c_approx + 2)):
                    if grid_data[i, j] > max_val:
                        max_val = grid_data[i, j]
                        max_r, max_c = i, j

            # Eliminar los resaltes anteriores si existen
            for patch in highlight_patches:
                patch.remove()
            highlight_patches.clear()

            # 1. Dibujar resalte CAFÉ en la celda donde se hizo click
            clicked_patch = Rectangle((c_approx - 0.5, r_approx - 0.5), width, height, 
                                      fill=False, edgecolor='saddlebrown', linewidth=3, zorder=8)
            ax.add_patch(clicked_patch)
            highlight_patches.append(clicked_patch)

            # 2. Dibujar resalte ROJO en la celda con el valor máximo
            max_patch = Rectangle((max_c - 0.5, max_r - 0.5), width, height, 
                                  fill=False, edgecolor='red', linewidth=3, zorder=9)
            ax.add_patch(max_patch)
            highlight_patches.append(max_patch)

            # Actualizar el título con 5 decimales
            ax.set_title(f"Click en ({min_x+c_approx}, {min_y+r_approx}) | Máx en ({min_x+max_c}, {min_y+max_r}): {max_val:.5f}", 
                         pad=20, color='red', weight='bold')
            fig.canvas.draw_idle()

    fig.canvas.mpl_connect('button_press_event', on_click)

    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()