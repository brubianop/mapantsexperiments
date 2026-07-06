import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_theme(style="whitegrid")
plt.rcParams.update({
    "font.size": 11,
    "axes.labelsize": 13,
    "axes.titlesize": 13,
    "xtick.labelsize": 11,
    "ytick.labelsize": 11,
    "figure.titlesize": 15
})

file_path = "../gama/Ants/includes/results_agents.csv"

if not os.path.exists(file_path):
    print(f"Error: No se encontró el archivo en la ruta: {file_path}")
    exit()

mis_columnas = ["Mode", "Scenario", "TiempoPromedio", "TortuosityPromedio"]
df = pd.read_csv(file_path, skiprows=1, names=mis_columnas)

# =========================================================
# LIMPIEZA DE DATOS
# =========================================================
for col in df.columns:
    df[col] = df[col].astype(str).str.replace('[', '', regex=False) \
                                 .str.replace(']', '', regex=False) \
                                 .str.replace("'", "", regex=False) \
                                 .str.replace('"', '', regex=False) \
                                 .str.strip()
    
df = df[df['Mode'].str.lower() != 'mode']

# Convertir a numérical
df['TortuosityPromedio'] = pd.to_numeric(df['TortuosityPromedio'], errors='coerce')
df['TiempoPromedio'] = pd.to_numeric(df['TiempoPromedio'], errors='coerce')
df = df.dropna(subset=['TortuosityPromedio', 'TiempoPromedio'])

# =========================================================
# SELECCIONAR LA MEJOR OCURRENCIA POR MÉTODO Y ESCENARIO
# =========================================================
df_sorted = df.sort_values(by=['Mode', 'Scenario', 'TiempoPromedio'], ascending=True)

df_best = df_sorted.drop_duplicates(subset=['Mode', 'Scenario'], keep='first')

print(f"Registros originales cargados: {len(df)}")
print(f"Registros únicos (mejores casos) tras el filtro: {len(df_best)}")

# =========================================================
# TORTUOSIDAD POR MÉTODO Y ESCENARIO (Barras agrupadas)
# =========================================================
plt.figure(figsize=(10, 6))
sns.barplot(
    data=df_best,
    x="Mode",
    y="TortuosityPromedio",
    hue="Scenario",
    palette="Set2"
)
plt.axhline(y=1.0, color='r', linestyle='--', alpha=0.7, label="Tortuosidad Ideal (1.0)")

plt.title("Tortuosidad en el MEJOR caso de Tiempo de Viaje")
plt.xlabel("Método / Esquema de Difusión")
plt.ylabel("Tortuosidad Promedio")
plt.legend(title="Escenario")
plt.tight_layout()

plt.savefig("grafica_tortuosidad_escenarios.png", dpi=300)
plt.close()

# =========================================================
# TIEMPOS DE VIAJE POR MÉTODO Y ESCENARIO
# =========================================================
plt.figure(figsize=(10, 6))
sns.barplot(
    data=df_best,
    x="Mode",
    y="TiempoPromedio",
    hue="Scenario",
    palette="Set2"
)

plt.title("Mínimo Tiempo de Viaje Alcanzado por Método y Escenario")
plt.xlabel("Método / Esquema de Difusión")
plt.ylabel("Tiempo Mínimo de Hallazgo (Ciclos)")
plt.legend(title="Escenario")
plt.tight_layout()

plt.savefig("grafica_tiempos_escenarios.png", dpi=300)
plt.close()

