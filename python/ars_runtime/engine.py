from .spec import load_spec, validate_spec
from .io import load_sources, emit_ard
from .dsl import apply_filters
from .joins import apply_joins
from .stats import summarize
from .metadata import build_metadata

def run_ars(spec_path: str, input_dir: str, output_dir: str, seed: int = 123) -> None:
    spec = load_spec(spec_path)
    validate_spec(spec)
    rng = seed
    doms = load_sources(spec, input_dir)
    doms = apply_filters(doms, spec.get("population"))
    doms = apply_joins(doms, spec.get("joins"))
    out  = summarize(doms, spec.get("analyses", []))
    meta = build_metadata(engine="Python", spec=spec, seed=seed)
    emit_ard(out, output_dir, metadata=meta)
