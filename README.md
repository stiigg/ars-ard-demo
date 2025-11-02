
# ARS → ARD Demo (R & SAS)

This bundle shows a minimal metadata-driven pipeline using CDISC ARS (JSON) to produce ARD.
It includes:
- `ars.json` — an example ARS spec describing a single analysis (AGE by ARM from ADSL).
- `R/ars_to_ard.R` — R script that reads `ars.json`, validates populations/groupings, computes the requested stats per analysis variable, and writes ARD.
- `SAS/ars_to_ard.sas` — SAS program that does the same using `LIBNAME JSON`.
- `data/ADSL.csv` — a tiny mock ADSL to run the demo out-of-the-box.

## Quick start (Python)
```bash
python3 ars_to_ard.py
```
Outputs: One ARD CSV per analysis (e.g., `ARD_DM_AGE_SUMMARY.csv`) in the project root with rows for every variable/statistic combination requested by the ARS metadata.  The Python implementation mirrors the original R script so the demo no longer depends on an R runtime (useful for lightweight CI environments).

## Quick start (R)
```bash
Rscript R/ars_to_ard.R
```
Outputs: Identical ARD CSV files, generated using the original R implementation.

## Quick start (SAS)
Update the infile paths in `SAS/ars_to_ard.sas` if needed, then run in your SAS environment.
Outputs: One ARD CSV per analysis (e.g., `ARD_DM_AGE_SUMMARY.csv`) in the project root.

## Notes
- Replace `data/ADSL.csv` with your real ADSL (same columns needed: USUBJID, ARM, AGE, SAFFL).
- Extend `ars.json` with more analyses (e.g., AE incidence) and add methods as required.
