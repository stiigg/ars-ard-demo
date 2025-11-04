# 🩸 Modernization Directive: ARS→ARD Demo Pipeline

### *Refactoring stiigg/ars-ard-demo into a submission-grade clinical automation framework.*

---

## 1. Objective

- [ ] Elevate `stiigg/ars-ard-demo` from a functional demo to a **regulatory-ready exemplar** of metadata-driven clinical programming — modular, validated, reproducible, and CI-enforced.
- [ ] Ensure the next release stands up to audit, not just academic curiosity.

---

## 2. SAS Modernization Plan

| Focus                  | Action Item                                                                                                                                   | Outcome                                                    | Status |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- | ------ |
| **Macro Architecture** | Decompose `ars_macros.sas` into domain-specific macro files (`io.sas`, `derive.sas`, `util.sas`). Add parameter tables and `%* DOC:` headers. | Modular, reviewable, auditable macros.                     | [ ]    |
| **JSON Handling**      | Replace text parsing with `libname json` or a Python-bridge parser. Validate schema pre-execution.                                            | Deterministic, schema-verified ARS ingestion.              | [ ]    |
| **Output Contracts**   | Extend ARD output metadata: include analytic lineage JSON, schema version, and commit hash.                                                   | Traceable datasets satisfying ARD provenance expectations. | [ ]    |
| **Unit Testing**       | Add `%assert_*` macros, negative controls, and run them via `make test-sas`. Integrate into GitHub Actions.                                   | Continuous compliance verification.                        | [ ]    |
| **Logging Discipline** | Introduce structured log summaries; promote FATAL/WARN distinctions; fail fast.                                                               | Clean, machine-parsable logs for CI review.                | [ ]    |

---

## 3. R Engine Overhaul

| Focus                   | Action Item                                                                                        | Outcome                                      | Status |
| ----------------------- | -------------------------------------------------------------------------------------------------- | -------------------------------------------- | ------ |
| **Refactor to Package** | Convert the R script into an installable package with `/R`, `/man`, `/tests`. Use `roxygen2` docs. | Maintainable, testable codebase.             | [ ]    |
| **Pipeline Framework**  | Implement `targets` or `drake` for dependency-aware execution.                                     | Reproducible, restartable pipelines.         | [ ]    |
| **CLI Input Handling**  | Add `optparse`/`argparse` for parameters: spec path, input data, output directory.                 | Environment-agnostic automation.             | [ ]    |
| **Error Handling**      | Wrap major stages in `tryCatch()` with contextual logging + `sessionInfo()`.                       | Transparent diagnostics and crash forensics. | [ ]    |
| **ARD Metadata**        | Embed runtime metadata (commit SHA, engine version, schema version) in every output.               | Guaranteed analytic lineage.                 | [ ]    |

---

## 4. Cross-Language Validation & CI/CD

| Focus                      | Action Item                                                                                     | Outcome                              | Status |
| -------------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------ | ------ |
| **Parity Testing**         | Promote `compare_ard.py` to a validator producing JSON summaries + exit codes for CI gating.    | Objective equivalence metrics.       | [ ]    |
| **Edge-Case Datasets**     | Add synthetic datasets covering missing data, extreme stratification, and protocol shifts.      | Stress-tested compliance resilience. | [ ]    |
| **Continuous Integration** | Expand `ci-r.yml` and `ci-sas.yml`: run full pipelines, diff ARDs, upload reports as artifacts. | Push-to-validate automation.         | [ ]    |
| **Artifact Provenance**    | Record lineage manifests (inputs, versions, hashes) in `/out/manifest.json`.                    | End-to-end reproducibility trail.    | [ ]    |

---

## 5. Documentation & Governance

- [ ] **README Overhaul:** add architecture diagram + “spec-to-ARD in 60 s” walkthrough.
- [ ] **Developer Guide:** include style guide, macro header template, R package structure, and CI workflow summary.
- [ ] **Contribution Standards:** enforce pre-commit checks for log noise, undocumented parameters, and un-versioned outputs.

---

## 6. Deliverables (v2 Milestone)

| Deliverable                 | Description                                  | Status |
| --------------------------- | -------------------------------------------- | ------ |
| Modular SAS macro library   | Documented, versioned macros with unit tests | [ ]    |
| R package engine            | Function-based pipeline with CLI interface   | [ ]    |
| JSON schema enforcement     | Shared schema validation across R/SAS        | [ ]    |
| Enhanced CI/CD              | Full parity tests + artifact uploads         | [ ]    |
| Provenance manifest         | Machine-readable lineage per run             | [ ]    |
| Edge-case dataset suite     | Realistic compliance stress tests            | [ ]    |

---

## 7. The Standard to Beat

- [ ] Run end-to-end with one `make all` command.
- [ ] Produce zero unhandled warnings in either engine.
- [ ] Validate ARS, generate ARDs, and compare outputs automatically.
- [ ] Output datasets that explain themselves — lineage, version, and metadata embedded.
- [ ] Pass CI parity checks and publish validation artifacts.

---

> **Bottom line:**
> The next iteration isn’t just a demo. It’s your argument that *regulatory automation can be beautiful, disciplined, and verifiable*.
> Every unchecked box above is a future audit headache — tick them now.

---

Would you prefer to track this roadmap as a Markdown document (this file) or convert it into a GitHub Project board with cards for each action item?
