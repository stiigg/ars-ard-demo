import json
from jsonschema import validate, Draft202012Validator
from pathlib import Path

def load_spec(path: str) -> dict:
    return json.loads(Path(path).read_text())

def validate_spec(spec: dict) -> None:
    # Wire in schemas/ars.schema.json
    pass
