"""Generate a parity report between ARD outputs produced by each engine."""

from __future__ import annotations

import argparse
import itertools
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Sequence

import numpy as np
import pandas as pd


POTENTIAL_KEY_COLUMNS: Sequence[str] = (
    "ANALYSISID",
    "ANALYSIS_ID",
    "PARAM",
    "PARAMCD",
    "PARAMN",
    "PARAMCAT",
    "PARAMCATCD",
    "PARAMCATN",
    "STAT",
    "ARM",
    "ARMCD",
    "ARMN",
    "GROUP",
    "GROUP1",
    "GROUP1_LEVEL",
    "GROUP2",
    "GROUP2_LEVEL",
    "GROUP3",
    "GROUP3_LEVEL",
    "POPULATION",
    "DATASET",
    "METHOD",
    "VARIABLE",
    "VARIABLE_LABEL",
    "STUDYID",
    "SAP_SECTION",
)


@dataclass
class ComparisonResult:
    """Container for the result of a pairwise ARD comparison."""

    analysis_id: str
    pair_label: str
    errors: List[str] = field(default_factory=list)
    samples: Dict[str, pd.DataFrame] = field(default_factory=dict)

    @property
    def status(self) -> str:
        return "match" if not self.errors else "mismatch"


def list_analysis_ids(directory: Path) -> Dict[str, Path]:
    """Return mapping of analysis identifier to ARD CSV within *directory*."""

    files: Dict[str, Path] = {}
    for path in sorted(directory.glob("ARD_*.csv")):
        analysis_id = path.stem.replace("ARD_", "", 1)
        files[analysis_id] = path
    return files


def select_key_columns(df_a: pd.DataFrame, df_b: pd.DataFrame) -> List[str]:
    """Pick reasonable join keys shared between two ARD frames."""

    shared = [c for c in POTENTIAL_KEY_COLUMNS if c in df_a.columns and c in df_b.columns]
    if shared:
        return shared

    shared = [
        c
        for c in df_a.columns
        if c in df_b.columns and c.upper() not in {"VALUE", "N", "MEAN", "SD", "SE", "MIN", "MAX", "Q1", "Q3", "CV"}
    ]
    if shared:
        return sorted(shared)

    return sorted(set(df_a.columns) & set(df_b.columns))


def _to_numeric(series: pd.Series) -> pd.Series:
    converted = pd.to_numeric(series, errors="coerce")
    if converted.notna().any():
        return converted
    return series


def _record_duplicate_rows(
    result: ComparisonResult,
    frame: pd.DataFrame,
    keys: Sequence[str],
    label: str,
) -> bool:
    """Add duplicate key diagnostics to *result* when present.

    Returns ``True`` when duplicates were found. Duplicate keys indicate that the
    inferred join would not produce a stable 1:1 mapping which could hide or
    amplify mismatches. The comparison short-circuits in this situation and the
    caller is expected to stop further processing.
    """

    duplicate_mask = frame.duplicated(subset=list(keys), keep=False)
    if not duplicate_mask.any():
        return False

    dup_rows = frame.loc[duplicate_mask, list(keys)].drop_duplicates()
    result.errors.append(
        "Duplicate key rows detected in {label}; unable to perform a reliable comparison.".format(
            label=label
        )
    )
    result.samples[f"duplicate_keys_{label.lower()}"] = dup_rows.head(10)
    return True


def compare_tables(
    analysis_id: str,
    left_label: str,
    left: Path,
    right_label: str,
    right: Path,
    tolerance: float = 1e-8,
) -> ComparisonResult:
    """Compare two ARD CSV files and capture mismatches."""

    result = ComparisonResult(analysis_id=analysis_id, pair_label=f"{left_label} vs {right_label}")

    df_left = pd.read_csv(left)
    df_right = pd.read_csv(right)

    missing_cols = sorted(set(df_left.columns) - set(df_right.columns))
    extra_cols = sorted(set(df_right.columns) - set(df_left.columns))
    if missing_cols:
        result.errors.append(f"Columns only in {left_label}: {', '.join(missing_cols)}")
    if extra_cols:
        result.errors.append(f"Columns only in {right_label}: {', '.join(extra_cols)}")

    keys = select_key_columns(df_left, df_right)
    if not keys:
        result.errors.append("No shared columns available for comparison.")
        return result

    if _record_duplicate_rows(result, df_left, keys, left_label):
        return result
    if _record_duplicate_rows(result, df_right, keys, right_label):
        return result

    merged = df_left.merge(
        df_right,
        on=keys,
        how="outer",
        suffixes=("_left", "_right"),
        indicator=True,
    )

    only_left = merged[merged["_merge"] == "left_only"]
    only_right = merged[merged["_merge"] == "right_only"]
    if not only_left.empty:
        result.errors.append(f"{len(only_left)} rows only present in {left_label}.")
        result.samples[f"rows_only_in_{left_label}"] = only_left[keys].head(5)
    if not only_right.empty:
        result.errors.append(f"{len(only_right)} rows only present in {right_label}.")
        result.samples[f"rows_only_in_{right_label}"] = only_right[keys].head(5)

    both = merged[merged["_merge"] == "both"].copy()
    if both.empty:
        return result

    value_columns = [c for c in df_left.columns if c in df_right.columns and c not in keys]
    for column in value_columns:
        left_col = f"{column}_left"
        right_col = f"{column}_right"
        left_series = _to_numeric(both[left_col])
        right_series = _to_numeric(both[right_col])

        if np.issubdtype(left_series.dtype, np.number) or np.issubdtype(right_series.dtype, np.number):
            diff_mask = ~np.isclose(
                left_series.astype(float),
                right_series.astype(float),
                atol=tolerance,
                rtol=0.0,
                equal_nan=True,
            )
        else:
            diff_mask = left_series.fillna("").astype(str) != right_series.fillna("").astype(str)

        if diff_mask.any():
            mismatched = both.loc[diff_mask, keys + [left_col, right_col]].head(5)
            result.errors.append(
                f"Column '{column}' differs in {diff_mask.sum()} row(s) (showing up to 5)."
            )
            result.samples[f"{column}_differences"] = mismatched

    return result


def build_report(results: Iterable[ComparisonResult]) -> str:
    """Render the comparison results to a Markdown report."""

    rows = list(results)
    lines = [
        "# ARD Parity Report",
        "",
        "Generated from comparing ARD outputs across engines.",
        "",
        "| Analysis ID | Comparison | Status |",
        "| --- | --- | --- |",
    ]
    for row in rows:
        lines.append(f"| {row.analysis_id} | {row.pair_label} | {row.status} |")

    mismatches = [r for r in rows if r.errors]
    if mismatches:
        lines.append("")
        lines.append("## Detailed mismatches")
        lines.append("")
        for entry in mismatches:
            lines.append(f"### {entry.analysis_id} – {entry.pair_label}")
            lines.append("")
            for error in entry.errors:
                lines.append(f"- {error}")
            for label, sample in entry.samples.items():
                lines.append("")
                lines.append(f"#### {label}")
                lines.append("")
                lines.append("```")
                lines.extend(sample.to_string(index=False).splitlines())
                lines.append("```")
                lines.append("")

    else:
        lines.append("")
        lines.append("All ARD outputs match within the configured tolerance.")

    return "\n".join(lines).strip() + "\n"


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--r", type=Path, required=True, help="Directory containing R ARDs")
    parser.add_argument("--py", type=Path, required=True, help="Directory containing Python ARDs")
    parser.add_argument("--sas", type=Path, required=True, help="Directory containing SAS ARDs")
    parser.add_argument(
        "--report",
        type=Path,
        required=True,
        help="Destination for the Markdown parity report",
    )
    parser.add_argument(
        "--tolerance",
        type=float,
        default=1e-8,
        help="Numeric tolerance when comparing values (default: 1e-8)",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> None:
    args = parse_args(argv)

    directories = {
        "R": args.r,
        "Python": args.py,
        "SAS": args.sas,
    }

    for label, directory in directories.items():
        if not directory.exists():
            raise FileNotFoundError(f"{label} directory not found: {directory}")
        if not any(directory.glob("ARD_*.csv")):
            raise FileNotFoundError(
                f"{label} directory {directory} does not contain any ARD_*.csv files"
            )

    listings = {label: list_analysis_ids(path) for label, path in directories.items()}
    common_ids = set.intersection(*(set(ids.keys()) for ids in listings.values()))
    if not common_ids:
        raise ValueError("No common ARD CSV files were found across the supplied directories.")

    results: List[ComparisonResult] = []
    for analysis_id in sorted(common_ids):
        for (left_label, left_files), (right_label, right_files) in itertools.combinations(listings.items(), 2):
            left_path = left_files.get(analysis_id)
            right_path = right_files.get(analysis_id)
            if left_path and right_path:
                results.append(
                    compare_tables(
                        analysis_id,
                        left_label,
                        left_path,
                        right_label,
                        right_path,
                        tolerance=args.tolerance,
                    )
                )

    report = build_report(results)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(report, encoding="utf-8")

    mismatches = [result for result in results if result.errors]
    if mismatches:
        raise SystemExit(
            f"Detected {len(mismatches)} comparison mismatches. See {args.report} for details."
        )


if __name__ == "__main__":
    main()
