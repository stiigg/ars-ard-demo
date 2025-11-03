import pandas as pd

def apply_joins(doms: dict, joins: list | None) -> dict:
    if not joins: return doms
    out = dict(doms)
    for j in joins:
        left  = out[j["left"]["source"]]
        right = out[j["right"]["source"]]
        on = j["on"]
        how = j.get("type", "inner")
        out["ANALYSIS"] = left.merge(right, on=on, how=how)
    return out
