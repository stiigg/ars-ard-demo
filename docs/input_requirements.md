# Input Dataset Requirements

This document enumerates the expected columns for each mock clinical domain used by the ARS→ARD demo. All columns are required unless marked as optional. Additional sponsor-specific columns may be included as needed.

## ADSL (Subject-Level Analysis Dataset)

| Column | Type | Notes |
| --- | --- | --- |
| `USUBJID` | character | Unique subject identifier |
| `STUDYID` | character | Study identifier |
| `ARM` | character | Planned treatment arm |
| `SEX` | character | Sex |
| `AGE` | numeric | Age at baseline |
| `SAFFL` | character | Safety population flag (`"Y"`/`"N"`) |
| `EFFFL` | character | Efficacy population flag (`"Y"`/`"N"`) |
| `RACE` | character | Race |
| `COUNTRY` | character | Country |
| `VISIT` | character | Visit label (for visit-level summaries) |

## AE (Adverse Events)

| Column | Type | Notes |
| --- | --- | --- |
| `USUBJID` | character | Links to ADSL |
| `AEDECOD` | character | MedDRA preferred term |
| `AETERM` | character | Reported term |
| `AESER` | character | Serious event flag |
| `AESEV` | character | Severity |
| `AESTDTC` | date | Start date |
| `AEENDTC` | date | End date (optional) |
| `ARM` | character | Planned treatment arm |
| `SAFFL` | character | Safety population flag |

## LAB (Laboratory Results)

| Column | Type | Notes |
| --- | --- | --- |
| `USUBJID` | character | Links to ADSL |
| `LBTESTCD` | character | Lab test code |
| `LBTEST` | character | Lab test name |
| `LBSTRESN` | numeric | Numeric result |
| `LBSTRESU` | character | Units |
| `VISIT` | character | Visit label |
| `LBDTC` | date | Collection date |
| `SAFFL` | character | Safety population flag |

## EFF (Efficacy Results)

| Column | Type | Notes |
| --- | --- | --- |
| `USUBJID` | character | Links to ADSL |
| `PARAMCD` | character | Parameter code |
| `PARAM` | character | Parameter description |
| `AVAL` | numeric | Analysis value |
| `AVISIT` | character | Analysis visit |
| `ARM` | character | Planned treatment arm |
| `EFFFL` | character | Efficacy population flag |

## Validation Notes

* Date columns use ISO 8601 format (YYYY-MM-DD) in the mock data.
* Character flags are represented as single uppercase characters for readability.
* Additional columns may be included; they will be ignored unless referenced in ARS metadata.
