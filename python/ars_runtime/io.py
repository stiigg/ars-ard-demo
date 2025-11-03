from pathlib import Path
import pandas as pd

def load_sources(spec: dict, input_dir: str) -> dict:
    doms = {}
    for s in spec.get("sources", []):
        p = Path(input_dir) / f"{s['name']}.csv"
        doms[s["name"]] = pd.read_csv(p)
    return doms

def emit_ard(tables: dict, output_dir: str, metadata: dict):
    out = Path(output_dir); out.mkdir(parents=True, exist_ok=True)
    for name, df in tables.items():
        df.to_csv(out / f"{name}.csv", index=False)
    (out / "metadata.json").write_text(__import__("json").dumps(metadata, indent=2))
