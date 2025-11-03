#!/usr/bin/env python3
import sys, pandas as pd, numpy as np

def main(dir_a, dir_b, analysis_id="DM_AGE_SUMMARY"):
    a = pd.read_csv(f"{dir_a}/ARD_{analysis_id}.csv")
    b = pd.read_csv(f"{dir_b}/ARD_{analysis_id}.csv")
    keys = [k for k in ["ANALYSISID","PARAMCD","STAT","ARM"] if k in a.columns and k in b.columns]
    m = a.merge(b, on=keys, how="outer", suffixes=("_a","_b"), indicator=True)
    errs = []

    miss = m[m["_merge"]=="left_only"]
    extra= m[m["_merge"]=="right_only"]
    if not miss.empty or not extra.empty: errs.append("Row set mismatch.")

    both = m[m["_merge"]=="both"]
    if "VALUE_a" in both and "VALUE_b" in both:
        diff = (both["VALUE_a"].astype(float) - both["VALUE_b"].astype(float)).abs() > 1e-8
        if diff.any(): errs.append("Numeric differences exceed tolerance (1e-8).")

    if errs:
        print("\n".join(errs)); sys.exit(1)
    print("ARDs match within tolerance.")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: compare_ard.py <dir_a> <dir_b> [analysis_id]"); sys.exit(2)
    aid = sys.argv[3] if len(sys.argv) > 3 else "DM_AGE_SUMMARY"
    main(sys.argv[1], sys.argv[2], aid)
