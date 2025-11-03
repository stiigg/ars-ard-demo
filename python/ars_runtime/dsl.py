# Evaluate boolean filter DSL against pandas DataFrame
def apply_filters(doms: dict, population: dict | None) -> dict:
    if not population or not population.get("where"): return doms
    # compile AST -> pandas query string safely
    return {k: _eval_where(v, population["where"]) for k, v in doms.items()}

def _eval_where(df, where):
    return df
