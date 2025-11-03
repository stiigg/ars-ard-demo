import numpy as np
import pandas as pd

def summarize(doms: dict, analyses: list) -> dict:
    results = {}
    for a in analyses:
        df = doms.get(a.get("source","ANALYSIS")).copy()
        gb = a.get("group_by", [])
        var = a["variable"]
        statset = a.get("statistics", ["n","mean","sd","median","q1","q3","min","max","se","cv"])
        g = df.groupby(gb, dropna=False)[var]
        out = pd.DataFrame(index=g.size().index)
        if "n" in statset: out["N"] = g.size().values
        if "mean" in statset: out["MEAN"] = g.mean().values
        if "sd" in statset: out["SD"] = g.std(ddof=1).values
        # ... fill others deterministically ...
        out = out.reset_index()
        results[a.get("id", var)] = out
    return results
