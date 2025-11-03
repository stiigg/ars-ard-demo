from datetime import datetime, timezone
import os

def build_metadata(engine: str, spec: dict, seed: int) -> dict:
    return {
        "ENGINE": engine,
        "ENGINE_VERSION": os.getenv("PY_ENGINE_VERSION","3.x"),
        "RUN_DATETIME": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "GIT_SHA": os.getenv("GITHUB_SHA"),
        "INPUTS": [s["name"] for s in spec.get("sources",[])],
        "ARS_SPEC_VERSION": spec.get("version"),
        "DATA_HASHES": {},  # TODO fill with per-file checksums
        "SEED": seed
    }
