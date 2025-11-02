# Analysis Results Dataset (ARD) Specification

The ARS→ARD demo produces summary datasets designed to mimic CDISC ADaM-style Analysis Result Datasets. Each dataset shares the same structure and is intended to support traceability back to the ARS metadata and source domains.

## Required Columns

| Column | Type | Description |
| --- | --- | --- |
| `ANALYSISID` | character | Identifier of the analysis definition in ARS |
| `PARAMCD` | character | Parameter code being summarised |
| `PARAM` | character | Parameter label |
| `STAT` | character | Requested statistic (e.g., `MEAN`, `SD`) |
| `VALUE` | numeric | Calculated value |
| `POPNAME` | character | Population label (e.g., `SAFETY`, `EFFICACY`) |
| `ANLGRP` | character | Concatenated grouping levels (e.g., `ARM=Placebo|SEX=F`) |
| `N` | integer | Count of records contributing to the statistic |
| `DENOM` | integer | Denominator (population count) |
| `SOURCEVAR` | character | Variable analysed |
| `METHOD` | character | Method description or identifier |
| `SRC_DATASET` | character | Source dataset name (e.g., `ADSL`) |
| `RUNID` | character | Unique run identifier |
| `ARSREF` | character | Reference to ARS JSON element (JSON Pointer or similar) |
| `TIMESTAMP` | datetime | ISO 8601 timestamp for record creation |

## Optional Columns

| Column | Type | Description |
| --- | --- | --- |
| `CONF_LOW` | numeric | Lower confidence interval bound |
| `CONF_HIGH` | numeric | Upper confidence interval bound |
| `NOTES` | character | Free-form notes |

## Column Ordering

Outputs should follow the required column order listed above, with optional columns appended. This simplifies downstream comparisons and ensures parity between R and SAS pipelines.

## Provenance Expectations

* `RUNID` should be a UUID or timestamp string unique to each execution.
* `ARSREF` should point to the relevant element in the ARS JSON (e.g., `ars_age.json#analyses[0]`).
* `TIMESTAMP` should capture the time the row was generated in UTC.

## File Naming Convention

Generated ARDs should follow `ARD_<DOMAIN>_<ANALYSIS>.csv` to align with existing examples and make it obvious which analysis each file represents.

## Validation

Automated checks should verify:

1. Presence of all required columns.
2. Correct column order.
3. Valid data types (`VALUE` numeric, `TIMESTAMP` parseable, etc.).
4. `ARSREF` values resolve to entries in the input ARS metadata.
