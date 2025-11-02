# Define-XML Mapping Notes

This document outlines how generated ARD columns map to Define-XML metadata elements. The intent is to illustrate traceability rather than to serve as a complete Define-XML specification.

| ARD Column | Define-XML Element | Notes |
| --- | --- | --- |
| `ANALYSISID` | `ItemDef/@OID` | Could map to an `ItemDef` representing the analysis identifier |
| `PARAMCD` | `ValueListRef` | Parameter code drives parameter-level metadata |
| `PARAM` | `ItemDef/Description` | Descriptive text for the parameter |
| `STAT` | `CodeListRef` | Statistic coded value |
| `VALUE` | `ItemDef/DataType` = `float` | Numeric result |
| `POPNAME` | `WhereClauseDef` | Defines subset used for the analysis |
| `ANLGRP` | `WhereClauseDef` | Combination of grouping variables |
| `N` | `ResultDisplay` | Supports traceability for denominators |
| `DENOM` | `ResultDisplay` | Denominator value |
| `SOURCEVAR` | `MethodDef` | References derivation of statistic |
| `METHOD` | `MethodDef/Description` | Human-readable method description |
| `SRC_DATASET` | `ItemGroupDef/@Name` | Indicates which domain supplied the data |
| `RUNID` | `AuditRecord/ID` | Execution identifier |
| `ARSREF` | `CommentDef` | Pointer back to ARS JSON fragment |
| `TIMESTAMP` | `AuditRecord/DateTimeStamp` | Execution timestamp |

## Usage Guidance

* Maintain a mapping table to translate ARS metadata entries into Define-XML components.
* Include the ARS JSON file as a referenced document in Define-XML to reinforce traceability.
* When generating Define-XML, ensure the ARD output location is recorded in a supplemental `leaf` element for easy retrieval.
