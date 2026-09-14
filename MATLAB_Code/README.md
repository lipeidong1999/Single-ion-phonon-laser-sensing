# MATLAB Code for Fig. 2(b)

This script fits the experimental BSB Rabi oscillations for datasets A1-A4 and B1-B4 to extract phonon number distributions. It automatically generates Excel files for plotting and Rabi fit validation plots.

## Requirements
- MATLAB (Tested on R2025a)
- Optimization Toolbox (required for `fmincon`)

## How to Run
1. Place `Fig2b_Data.zip` in the same folder as `Fig2b_Phonon_Fitting.m`.
2. Run `Fig2b_Phonon_Fitting.m`.
The script will automatically extract the data, locate the files, process all 8 datasets, and save the results.

*Note: The script also supports running directly within the full GitHub repository structure.*

## Output
A new folder `Analysis_Result/` will be created containing:
- `Final_Analysis_Report_*.xlsx`: Fit results and underlying data (used by the Python plotting notebook).
- `Fig_Rabi_*.pdf` / `.png`: Validation plots of the Rabi oscillation fits.

## Data Structure
The script expects the following structure inside `Fig2b_Data.zip`:
```text
Fig2b_Data/Raw_Data/
├── A1/ (contains folders 1-6, each with a bsb.txt)
├── ...
└── B4/
