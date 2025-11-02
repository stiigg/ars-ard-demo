# ARS→ARD Demo Roadmap

This roadmap captures the planned enhancements for the ARS→ARD demo. The goal is to evolve the proof-of-concept into a richer, multi-language showcase for metadata-driven analysis generation. Streams are intended to run in parallel; no timeline ordering is implied.

---

## 0) Repository scaffolding

**Create:**

```
/tests/                 # R tests
/.github/workflows/     # CI
/docs/                  # diagrams & spec docs
/data/                  # mock ADSL, AE, LAB, EFF datasets
/schema/                # JSON schema(s) for ars.json
```

**Definition of Done**

* Folders exist and are tracked.
* Continuous integration executes the test suite.
* `README.md` references `/docs/` and `/schema/`.

---

## 1) Metadata & data model (`ars.json` + schema)

**Tasks**

* Introduce rich ARS JSON supporting:
  * multiple analyses and variables per analysis
  * nested groupings such as `["ARM", "SEX", "VISIT"]`
  * population filters (e.g., `SAFFL == "Y"`, `AGE >= 65`)
  * derived variables and visit windows
* Add a JSON Schema to validate `ars.json` (store in `/schema/ars.schema.json`).
* Provide example ARS specs: `ars_age.json`, `ars_ae.json`, `ars_lab.json`, `ars_eff.json`.

**Acceptance criteria**

* `R/ars_to_ard.R --ars ars_age.json` passes schema validation and runs successfully.
* Invalid `ars.json` files fail fast with human-readable errors.

**Snippet (illustrative schema keys)**

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "ARS Spec",
  "type": "object",
  "required": ["analyses"],
  "properties": {
    "analyses": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["analysis_id", "population", "variables", "statistics"],
        "properties": {
          "analysis_id": {"type": "string"},
          "population": {"type": "object", "properties": {"filter": {"type": "string"}}},
          "grouping": {"type": "array", "items": {"type": "string"}},
          "variables": {"type": "array", "items": {"type": "string"}},
          "statistics": {"type": "array", "items": {"type": "string"}},
          "windows": {"type": "array", "items": {"type": "object"}},
          "derivations": {"type": "array", "items": {"type": "object"}}
        }
      }
    }
  }
}
```

---

## 2) Input datasets (mock realism)

**Tasks**

* Retain `data/ADSL.csv`; add `data/AE.csv`, `data/LAB.csv`, and `data/EFF.csv` with small, realistic structures.
* Document required columns per domain in `/docs/input_requirements.md`.

**Acceptance criteria**

* Each example ARS specification runs end-to-end on the mock data to produce ARD outputs.

---

## 3) R pipeline hardening (`R/ars_to_ard.R`)

**Tasks**

* Introduce schema validation (`jsonvalidate`, `jsonlite`, or equivalent) before processing.
* Check input domain columns against documented requirements.
* Expand grouping/statistics engine to handle multiple variables and statistics.
* Emit structured logging for progress, warnings, and validation results.
* Capture provenance metadata in `/run/run_metadata.json` for each execution.

**Acceptance criteria**

* Invalid metadata or missing columns trigger clear errors with actionable guidance.
* `run_metadata.json` records ARS hash, script version, execution timestamps, datasets used, and record counts.

**Snippet (R helper functions)**

```r
message_step <- function(msg) message(sprintf("[ARS→ARD] %s", msg))

require_cols <- function(df, cols, name) {
  missing <- setdiff(cols, names(df))
  if (length(missing)) {
    stop(sprintf("%s missing columns: %s", name, paste(missing, collapse = ", ")), call. = FALSE)
  }
}
```

---

## 4) SAS pipeline hardening (`SAS/ars_to_ard.sas`)

**Tasks**

* Use `LIBNAME JSON` to ingest the richer schema.
* Provide macroized checks for required columns, missing domains, and validation feedback.
* Build a macro library (`SAS/macros/*.sas`) with `%read_ars`, `%validate_inputs`, `%summarize`, `%emit_ard`, and `%write_run_meta`.

**Acceptance criteria**

* R and SAS pipelines yield equivalent ARD outputs within numeric tolerance.
* SAS logs highlight validation steps and warnings explicitly.

---

## 5) ARD structure & traceability

**Tasks**

* Standardize ARD columns:
  `ANALYSISID, PARAMCD, PARAM, STAT, VALUE, POPNAME, ANLGRP, N, DENOM, SOURCEVAR, METHOD, SRC_DATASET, RUNID, ARSREF, TIMESTAMP`.
* Enforce column order and data types across outputs.
* Document the ARD data dictionary in `/docs/ARD_spec.md`.
* Provide a Define-XML mapping example in `/docs/define_xml_mapping.md`.

**Acceptance criteria**

* Generated ARDs include the standardized columns in the expected order.
* Documentation aligns with produced outputs.

---

## 6) Output validation & parity checks

**Tasks**

* Add R scripts to diff ARDs produced by R and SAS, respecting numeric tolerances.
* Validate ARD column presence and types before publishing results.

**Acceptance criteria**

* `tests/test-ard-parity.R` passes with the mock datasets.
* CI surfaces detailed diffs when parity fails.

---

## 7) Automated testing (`/tests`) & fixtures

**Tasks**

* Implement `testthat` tests covering schema validation errors, column checks, multi-variable groupings, and ARD structure.
* Maintain golden ARD files for AGE, AE, LAB, and EFF scenarios.

**Acceptance criteria**

* `devtools::test()` passes locally and in CI.

---

## 8) Continuous integration (`.github/workflows/ci.yml`)

**Tasks**

* Install R dependencies, execute tests, and archive ARD outputs as build artifacts.
* (Optional) Add SAS execution or reuse stored SAS outputs for parity tests when SAS is unavailable.

**Acceptance criteria**

* Pushes and pull requests trigger CI runs that validate metadata, execute pipelines, and publish artifacts.

**Snippet (minimal workflow)**

```yaml
name: CI
on: [push, pull_request]
jobs:
  r-ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: r-lib/actions/setup-r@v2
      - name: Install dependencies
        run: Rscript -e 'install.packages(c("jsonlite", "testthat"))'
      - name: Run tests
        run: Rscript -e 'dir.create("out", showWarnings = FALSE); testthat::test_dir("tests")'
      - name: Upload ARDs
        uses: actions/upload-artifact@v4
        with:
          name: ards
          path: out/
```

---

## 9) Documentation & teaching materials

**Tasks**

* Update `README.md` with an architecture overview, quick-start instructions, and links to the expanded documentation.
* Author a tutorial (`docs/tutorial.Rmd`, with rendered HTML) demonstrating editing ARS metadata, running the pipeline, and interpreting outputs.
* Draft a contribution guide (`CONTRIBUTING.md`) describing style conventions, tests, and PR workflow.
* Expand `/docs/input_requirements.md`, `/docs/ARD_spec.md`, and `/docs/define_xml_mapping.md` with implementation details.

**Acceptance criteria**

* New contributors can clone the repo, run examples, and extend the metadata without additional guidance.

---

## 10) Interoperability & modularity

**Tasks**

* Align ARS metadata fields with CDISC ARS JSON naming where practical.
* Support URLs or API sources for ARS metadata (e.g., `--ars https://.../ars.json`).
* Refactor SAS code into reusable macros under `SAS/macros/`.

**Acceptance criteria**

* ARS specifications interoperate with other tooling and SAS usage is macro-based and reusable.

---

## Quick copy-paste checklists

### Metadata & schema

* [ ] `/schema/ars.schema.json` validates example specs
* [ ] `ars_*.json` examples (AGE, AE, LAB, EFF) added
* [ ] R/SAS fail fast on invalid ARS metadata

### Data & inputs

* [ ] `data/AE.csv`, `data/LAB.csv`, `data/EFF.csv` added
* [ ] `/docs/input_requirements.md` documents required columns

### Pipelines (R & SAS)

* [ ] Required column checks implemented
* [ ] Multi-variable and multi-stat grouping supported
* [ ] Logging and warnings implemented
* [ ] `run_metadata.json` emitted per run

### ARD & provenance

* [ ] Standard ARD columns enforced and ordered
* [ ] `/docs/ARD_spec.md` and `/docs/define_xml_mapping.md` align with outputs

### Validation & parity

* [ ] R↔SAS parity tests implemented
* [ ] ARD schema/type checks pass

### Tests & CI

* [ ] `tests/` contains unit and golden tests
* [ ] CI builds, tests, and publishes artifacts

### Docs & onboarding

* [ ] README updated with diagrams and quick start
* [ ] `docs/tutorial.Rmd` authored and rendered
* [ ] `CONTRIBUTING.md` created

### Interoperability & macros

* [ ] ARS fields align with CDISC where feasible
* [ ] SAS macro library extracted under `SAS/macros/`

---

## Suggested additions

```
/schema/ars.schema.json
/docs/input_requirements.md
/docs/ARD_spec.md
/docs/define_xml_mapping.md
/docs/tutorial.Rmd
/tests/test-structure.R
/tests/test-parity.R
/.github/workflows/ci.yml
SAS/macros/read_ars.sas
SAS/macros/validate_inputs.sas
SAS/macros/summarize.sas
SAS/macros/emit_ard.sas
```

This roadmap will evolve as work is completed; update it as milestones are delivered or requirements change.
