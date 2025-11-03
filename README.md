# ARS → ARD Demo (R & SAS)

Minimal metadata-driven pipeline that turns a CDISC ARS JSON spec into Analysis Results Datasets (ARD).
R is the primary engine with SAS used for regulated parity checks, while Python utilities provide
schema validation and diffing support.

## Quick start

```bash
make validate       # no-deps ARS validation (works in locked CI)
make run            # R engine → out/
# when SAS runner is available:
make run-sas        # SAS engine → out_sas/
make diff           # compare ARD parity (requires pandas/numpy locally)
```

Outputs live under `out/` (R) and `out_sas/` (SAS) with filenames like `ARD_DM_AGE_SUMMARY.csv`.
Each ARD row includes the requested statistics and lineage fields (`ENGINE`, `ENGINE_VERSION`, `RUN_DATETIME`).

## Repository layout

- `ars.json` — demo ARS spec (AGE by ARM from ADSL)
- `schema/ars.schema.json` — minimal JSON Schema used by `make validate`
- `R/ars_to_ard.R` — CLI driver for the R engine
- `SAS/macros/ars_macros.sas` + `SAS/ars_to_ard.sas` — SAS implementation and helper macros
- `python/ars_to_ard.py` — optional Python engine (kept for experimentation)
- `scripts/` — helper utilities (`run.sh`, `validate_ars.py`, `compare_ard.py`)
- `data/ADSL.csv` — mock input dataset

## Continuous integration

- `.github/workflows/ci-r.yml` runs the R engine on GitHub-hosted Linux runners
- `.github/workflows/ci-sas.yml` targets a self-hosted runner with SAS for parity checks

Artifacts from both engines can be compared with `make diff`, helping ensure numerical parity
between implementations.
