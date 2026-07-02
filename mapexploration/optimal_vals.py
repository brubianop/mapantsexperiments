import os
import pandas as pd
import matplotlib.pyplot as plt

def generar_reporte_optimos(file_path):
    if not os.path.exists(file_path):
        print(f"Error: No se encontró el archivo: {file_path}")
        return
    mis_columnas = ["Mode", "Rate", "MSE", "Anisotropy", "Circularity", "MaxMinRatio"]
    df = pd.read_csv(file_path, skiprows=2, names=mis_columnas)
    
    df["Mode"] = df["Mode"].astype(str).str.replace('[','', regex=False)\
                                       .str.replace(']','', regex=False)\
                                       .str.replace("'", "", regex=False)\
                                       .str.replace('"', '', regex=False)\
                                       .str.strip()
                                       
    for col in mis_columnas[1:]:
        df[col] = pd.to_numeric(df[col], errors='coerce')
    df = df.dropna(subset=["Rate", "MSE"])
    df = df[df["Rate"] >= 0.10]

    # ÓPTIMO
    #best_circ = df["Circularity"].max()
    #best_ani  = df["Anisotropy"].min()
    #df_sano = df[(df["Circularity"] >= best_circ * 0.80 & df["Circularity"] >= 0.) & (df["Anisotropy"] <= best_ani * 0.20)]


    # RESULTADOS INDIVIDUALES
    #df_sano en loop
    for modo, grupo in df.groupby("Mode"):

        print("\n" + "=" * 65)
        print(f"MÉTODO: {modo}")
        print("=" * 65)

        # ======================================================
        # ÓPTIMO GEOMÉTRICO (ANISOTROPÍA)
        # ======================================================
        opt_ani = grupo.loc[grupo["Anisotropy"].idxmin()]

        print("\n[ÓPTIMO GEOMÉTRICO - ANISOTROPÍA]")
        print(f"Tasa Óptima: {opt_ani['Rate']:.2f}")
        print(f"Anisotropía: {opt_ani['Anisotropy']:.4f}")
        print(f"Circularidad: {opt_ani['Circularity']:.4f}")
        print(f"MSE: {opt_ani['MSE']:.6f}")

        print("-" * 65)

        # ======================================================
        # ÓPTIMO NUMÉRICO (MSE)
        # ======================================================
        opt_mse = grupo.loc[grupo["MSE"].idxmin()]

        print("\n[ÓPTIMO NUMÉRICO - MSE]")
        print(f"Tasa Óptima: {opt_mse['Rate']:.2f}")
        print(f"Anisotropía: {opt_mse['Anisotropy']:.4f}")
        print(f"Circularidad: {opt_mse['Circularity']:.4f}")
        print(f"MSE: {opt_mse['MSE']:.6f}")

        print("-" * 65)

        # ======================================================
        # ÓPTIMO GEOMÉTRICO PURO (CIRCULARIDAD)
        # ======================================================
        opt_circ = grupo.loc[grupo["Circularity"].idxmax()]

        print("\n[ÓPTIMO GEOMÉTRICO - CIRCULARIDAD]")
        print(f"Tasa Óptima: {opt_circ['Rate']:.2f}")
        print(f"Anisotropía: {opt_circ['Anisotropy']:.4f}")
        print(f"Circularidad: {opt_circ['Circularity']:.4f}")
        print(f"MSE: {opt_circ['MSE']:.6f}")

        print("-" * 65)

    #RESULTADOS MIXTOS, MEJOR ELECCIÓN
    # =========================================================
    # SCORE MULTICRITERIO NORMALIZADO
    # =========================================================

    df = df.copy()

    # Agrupar normalización por método
    df["MSE_norm"] = df.groupby("Mode")["MSE"].transform(
        lambda x: (x - x.min()) / (x.max() - x.min() + 1e-12)
    )

    df["Anisotropy_norm"] = df.groupby("Mode")["Anisotropy"].transform(
        lambda x: (x - x.min()) / (x.max() - x.min() + 1e-12)
    )

    df["Circularity_norm"] = df.groupby("Mode")["Circularity"].transform(
        lambda x: (x - x.min()) / (x.max() - x.min() + 1e-12)
    )

    df["Circularity_cost"] = 1 - df["Circularity_norm"]

    # =========================================================
    # SCORE GLOBAL
    # =========================================================
    df["Score"] = (
        df["MSE_norm"] +
        df["Anisotropy_norm"] +
        df["Circularity_cost"]
    )

    print("\n" + "="*65)
    print("=== ÓPTIMO MULTICRITERIO (ROBUSTO) ===")
    print("="*65)

    for modo, grupo in df.groupby("Mode"):

        opt = grupo.loc[grupo["Score"].idxmin()]

        print(f"\nMÉTODO: {modo}")
        print(f"Rate Óptimo:        {opt['Rate']:.2f}")
        print(f"MSE:               {opt['MSE']:.6f}")
        print(f"Anisotropía:       {opt['Anisotropy']:.4f}")
        print(f"Circularidad:      {opt['Circularity']:.4f}")
        print(f"SCORE GLOBAL:      {opt['Score']:.4f}")
        print("-" * 65)

    #--------------------------------------------------------------------------#     
    df_plot = df.copy()
    df_plot.loc[df_plot["Anisotropy"] > 3.0, "Anisotropy"] = 3.0

    # =========================================================================
    # TASA DE DIFUSIÓN VS ERROR NUMÉRICO (MSE)
    # =========================================================================
    plt.figure(figsize=(10, 5))
    for modo, grupo in df_plot.groupby("Mode"):
        grupo = grupo.sort_values("Rate")
        plt.plot(grupo["Rate"], grupo["MSE"], marker='o', linewidth=2, label=modo)
    plt.title("Estabilidad Numérica: Tasa de Difusión vs MSE", fontsize=12, fontweight='bold')
    plt.xlabel(r"Tasa de Difusión ($\Delta t$)")
    plt.ylabel("MSE (Escala Log)")
    plt.yscale("log")
    plt.grid(True, which="both", linestyle="--", alpha=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig("1_estabilidad_mse_completo.png", dpi=300)
    plt.close()

    # =========================================================================
    # TASA DE DIFUSIÓN VS FACTOR DE CIRCULARIDAD
    # =========================================================================
    plt.figure(figsize=(10, 5))
    for modo, grupo in df_plot.groupby("Mode"):
        grupo = grupo.sort_values("Rate")
        plt.plot(grupo["Rate"], grupo["Circularity"], marker='s', linewidth=2, label=modo)
    plt.axhline(y=0.78, color='gray', linestyle=':', label="Límite Moore (~0.78)")
    plt.title("Simetría Geométrica: Tasa de Difusión vs Circularidad", fontsize=12, fontweight='bold')
    plt.xlabel(r"Tasa de Difusión ($\Delta t$)")
    plt.ylabel(r"Factor de Circularidad ($C_g$)")
    plt.ylim(-0.05, 1.05)
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig("2_isotropia_circularidad_completo.png", dpi=300)
    plt.close()

    # =========================================================================
    # TASA DE DIFUSIÓN VS ANISOTROPÍA AXIAL
    # =========================================================================
    plt.figure(figsize=(10, 5))
    for modo, grupo in df_plot.groupby("Mode"):
        grupo = grupo.sort_values("Rate")
        plt.plot(grupo["Rate"], grupo["Anisotropy"], marker='^', linewidth=2, label=modo)
    plt.axhline(y=0.0, color='red', linestyle='--', alpha=0.5, label="Isotropía Absoluta (0.0)")
    plt.title("Distorsión Direccional: Tasa de Difusión vs Anisotropía", fontsize=12, fontweight='bold')
    plt.xlabel(r"Tasa de Difusión ($\Delta t$)")
    plt.ylabel(r"Factor de Anisotropía ($\sigma_r / \mu_r$)")
    plt.ylim(-0.05, 3.2)
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig("3_estabilidad_anisotropia_completo.png", dpi=300)
    plt.close()


    # =========================================================================
    # SCORE MULTICRITÉRIO
    # =========================================================================
    plt.figure(figsize=(10,5))

    for modo, grupo in df.groupby("Mode"):
        grupo = grupo.sort_values("Rate")
        plt.plot(grupo["Rate"], grupo["Score"], marker='o', label=modo)

    plt.title("Score multicriterio vs Tasa de Difusión (Ciclo fijo = 300)")
    plt.xlabel("Tasa de Difusión")
    plt.ylabel("Score (menor es mejor)")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig("4_score_multicriterio.png", dpi=300)
    plt.close()
    
    print("\n>>> FIN. <<<")


if __name__ == "__main__":
    ruta_datos = "../gama/Ants/includes/optimal_vals_diff.csv"
    generar_reporte_optimos(ruta_datos)
