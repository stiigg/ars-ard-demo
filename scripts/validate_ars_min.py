#!/usr/bin/env python3
import sys, json

REQUIRED_TOP = ["version", "analyses"]
REQUIRED_ANALYSIS = ["analysis_id","population","dataset","variable","group_by","statistics"]
ALLOWED_STATS = {"N","MEAN","SD","MEDIAN","Q1","Q3","MIN","MAX","SE","CV"}

def err(msg): print(f"[SCHEMA] {msg}"); sys.exit(1)

if len(sys.argv) < 2:
    print("Usage: validate_ars_min.py <ars.json>"); sys.exit(2)

with open(sys.argv[1]) as f:
    ars = json.load(f)

for k in REQUIRED_TOP:
    if k not in ars: err(f"Missing top-level key: {k}")
if not isinstance(ars["analyses"], list) or len(ars["analyses"]) == 0:
    err("analyses must be a non-empty array")

for i, a in enumerate(ars["analyses"]):
    for k in REQUIRED_ANALYSIS:
        if k not in a: err(f"analyses[{i}]: missing '{k}'")
    if not isinstance(a["group_by"], list):
        err(f"analyses[{i}].group_by must be an array")
    if not isinstance(a["statistics"], list) or len(a["statistics"]) == 0:
        err(f"analyses[{i}].statistics must be a non-empty array")
    bad = [s for s in a["statistics"] if s not in ALLOWED_STATS]
    if bad: err(f"analyses[{i}].statistics contains unsupported values: {bad}")
    if "filter" not in a["population"]:
        err(f"analyses[{i}].population.filter missing")
    if "name" not in a["variable"]:
        err(f"analyses[{i}].variable.name missing")

print("ARS metadata is valid (minimal checks).")
