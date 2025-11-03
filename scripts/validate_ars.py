#!/usr/bin/env python3
import sys, json
from jsonschema import validate, Draft7Validator

if len(sys.argv) < 3:
    print("Usage: validate_ars.py <ars.json> <schema.json>"); sys.exit(2)

ars = json.load(open(sys.argv[1]))
schema = json.load(open(sys.argv[2]))
errs = sorted(Draft7Validator(schema).iter_errors(ars), key=lambda e: e.path)
if errs:
    for e in errs:
        print(f"[SCHEMA] {'/'.join([str(p) for p in e.path])}: {e.message}")
    sys.exit(1)
print("ARS metadata is valid.")
