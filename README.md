# Codes for "Dissipative quantum electrometry with a single-ion phonon laser"

This repository contains Python (QuTiP) and MATLAB codes, plus processed data, to reproduce all figures.

- `Fig1_Wigner_Reconstruction.ipynb` – Fig. 1
- `Fig2_Simulation_and_Fitting.ipynb` – Fig. 2
- `Fig3_Time_Evolution_and_Sensitivity_Map.ipynb` – Fig. 3
- `Fig4_S_phi_and_Liouvillian_Gap.ipynb` – Fig. 4
- `MATLAB_Code/Fig2b_Phonon_Fitting.m` – Fig. 2(b)
- `experimental_data/` – Processed data for all figures

Python notebooks run directly on Google Colab. Set `RECOMPUTE_DATA = False` to load pre-computed `.npz` files instantly, or `True` to re-run QuTiP simulations. The MATLAB script requires MATLAB R2025a with the Optimization Toolbox.
