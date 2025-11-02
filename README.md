
# ARS → ARD Demo (R & SAS)

This bundle shows a minimal metadata-driven pipeline using CDISC ARS (JSON) to produce ARD.
It now includes a growing ecosystem of metadata examples, documentation, and automation scaffolding described in the [roadmap](ROADMAP.md).

Key assets:

- `ars.json`, `ars_age.json`, `ars_ae.json`, `ars_lab.json`, `ars_eff.json` — ARS specifications covering multiple analyses.
- `R/ars_to_ard.R` — R script that reads ARS metadata, validates populations/groupings, computes the requested stats, and writes ARD.
- `SAS/ars_to_ard.sas` — SAS program that does the same using `LIBNAME JSON`.
- `data/ADSL.csv`, `data/AE.csv`, `data/LAB.csv`, `data/EFF.csv` — tiny mock domains to run the demo out-of-the-box.
- `schema/ars.schema.json` — JSON Schema describing the enriched ARS format.
- Documentation in [`docs/`](docs/) covering input requirements, ARD structure, Define-XML mapping, and a tutorial.

## Quick start (R)
```bash
Rscript R/ars_to_ard.R
```
Outputs: One ARD CSV per analysis (e.g., `ARD_DM_AGE_SUMMARY.csv`) in the project root with rows for every variable/statistic combination requested by the ARS metadata.
Refer to [`docs/tutorial.Rmd`](docs/tutorial.Rmd) for a step-by-step walkthrough.

## Quick start (SAS)
Update the infile paths in `SAS/ars_to_ard.sas` if needed, then run in your SAS environment.
Outputs: One ARD CSV per analysis (e.g., `ARD_DM_AGE_SUMMARY.csv`) in the project root.

## Notes

- Replace the mock data in `data/` with your real domains (see [`docs/input_requirements.md`](docs/input_requirements.md) for required columns).
- Extend the ARS JSON files with additional analyses and methods as required.
- Continuous integration scaffolding in [`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs placeholder tests and can be extended as functionality grows.
