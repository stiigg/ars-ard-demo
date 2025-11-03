#!/usr/bin/env python3
"""Convert ARS JSON specifications into ARD CSV outputs.

This is a Python port of the original R implementation so that the
repository no longer requires an R runtime (and therefore works in CI
systems where ``Rscript`` is unavailable).  The script keeps the same
output layout as the R version and implements the subset of the ARS
spec that the demo project relies on.
"""

from __future__ import annotations

import argparse
import ast
import csv
import json
import math
import statistics
from pathlib import Path
from typing import Dict, Iterator, List, Mapping, MutableMapping, Optional, Sequence, Tuple


class PopulationExpressionError(ValueError):
    """Raised when the population filter expression cannot be parsed."""


SUPPORTED_STAT_ALIASES: Mapping[str, str] = {
    "count": "n",
    "nnonmiss": "n_non_missing",
    "n_nonmiss": "n_non_missing",
    "n_non_missing": "n_non_missing",
    "nonmissing": "n_non_missing",
    "non_missing": "n_non_missing",
    "nmiss": "n_missing",
    "missing": "missing",
    "missing_count": "missing",
    "mean": "mean",
    "arithmetic_mean": "arithmetic_mean",
    "sd": "sd",
    "stddev": "stddev",
    "std": "std",
    "std_dev": "std",
    "se": "se",
    "stderr": "stderr",
    "var": "var",
    "variance": "variance",
    "median": "median",
    "q2": "median",
    "min": "min",
    "max": "max",
    "range": "range",
    "iqr": "iqr",
}


def slugify(text: str) -> str:
    """Return a file-name friendly slug similar to the R implementation."""

    slug_chars = ["_" if not ch.isalnum() else ch for ch in text]
    slug = "".join(slug_chars)
    slug = slug.strip("_")
    return slug.upper() or "ARD"


def method_label(method: Mapping[str, object]) -> str:
    label = method.get("label")
    if isinstance(label, str) and label.strip():
        return label

    method_type = str(method.get("type", "descriptive")).lower()
    return {
        "descriptive": "Descriptive statistics",
        "time_to_event": "Time-to-event analysis",
        "binary": "Binary analysis",
        "categorical": "Categorical analysis",
    }.get(method_type, method_type)


def default_statistics(method: Mapping[str, object]) -> List[str]:
    method_type = str(method.get("type", "descriptive")).lower()
    return {
        "descriptive": ["n", "mean", "sd", "median", "min", "max"],
        "categorical": ["n"],
        "binary": ["n", "mean"],
        "time_to_event": ["n", "median"],
    }.get(method_type, ["n"])


def normalise_stat_keyword(stat: str) -> str:
    stat_lower = stat.lower()
    if stat_lower == "n":
        return "n"

    if stat_lower in SUPPORTED_STAT_ALIASES:
        return SUPPORTED_STAT_ALIASES[stat_lower]

    if stat_lower.startswith("p") and stat_lower[1:].isdigit():
        return stat_lower

    if stat_lower.startswith("q") and len(stat_lower) == 2 and stat_lower[1] in "1234":
        quartile = {"1": 25, "2": 50, "3": 75, "4": 100}[stat_lower[1]]
        return f"p{quartile}"

    if stat_lower == "iqr":
        return "iqr"

    return stat_lower


def select_method_for_variable(
    methods: Sequence[Mapping[str, object]],
    variable: Mapping[str, object],
) -> Mapping[str, object]:
    if not methods:
        return {}

    var_name = str(variable.get("name", ""))

    def extract_target(method: Mapping[str, object]) -> Optional[str]:
        target = method.get("target")
        if isinstance(target, str):
            return target
        if isinstance(target, Mapping):
            value = target.get("variable") or target.get("name")
            if isinstance(value, str):
                return value
        return None

    for method in methods:
        target = extract_target(method)
        if target and target == var_name:
            return method

        method_vars = method.get("variables")
        if isinstance(method_vars, Sequence):
            for item in method_vars:
                if isinstance(item, Mapping):
                    candidate = item.get("name") or item.get("variable")
                    if isinstance(candidate, str) and candidate == var_name:
                        return method

    return methods[0]


def collect_statistics(
    variable: Mapping[str, object], method: Mapping[str, object]
) -> List[str]:
    def flatten(values: object) -> List[str]:
        if isinstance(values, Sequence) and not isinstance(values, (str, bytes)):
            result: List[str] = []
            for value in values:
                result.extend(flatten(value))
            return result
        if isinstance(values, str):
            return [values]
        return []

    variable_stats = flatten(variable.get("statistics"))
    if variable_stats:
        return variable_stats

    method_stats = flatten(method.get("statistics"))
    if method_stats:
        return method_stats

    return default_statistics(method)


def safe_float(value: Optional[str]) -> Optional[float]:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)

    text = str(value).strip()
    if not text:
        return None
    try:
        return float(text)
    except ValueError as exc:  # pragma: no cover - helpful error path
        raise ValueError(f"Value '{value}' is not numeric") from exc


def linear_quantile(sorted_values: Sequence[float], prob: float) -> float:
    if not sorted_values:
        return math.nan
    if prob <= 0:
        return sorted_values[0]
    if prob >= 1:
        return sorted_values[-1]

    h = (len(sorted_values) - 1) * prob
    lower = math.floor(h)
    upper = math.ceil(h)
    if lower == upper:
        return sorted_values[lower]
    fraction = h - lower
    return sorted_values[lower] + (sorted_values[upper] - sorted_values[lower]) * fraction


def compute_statistic(values: Sequence[Optional[float]], stat: str) -> float:
    cleaned = [value for value in values if value is not None]
    total = len(values)
    missing = total - len(cleaned)

    if stat in {"n", "n_non_missing"}:
        return len(cleaned)
    if stat in {"n_missing", "missing"}:
        return missing

    if not cleaned:
        return math.nan

    if stat in {"mean", "arithmetic_mean"}:
        return float(statistics.fmean(cleaned))
    if stat in {"sd", "stddev", "std", "stderr", "se"}:
        if len(cleaned) < 2:
            stdev = 0.0
        else:
            stdev = statistics.stdev(cleaned)
        if stat in {"stderr", "se"}:
            return float(stdev / math.sqrt(len(cleaned))) if cleaned else math.nan
        return float(stdev)
    if stat in {"var", "variance"}:
        if len(cleaned) < 2:
            return 0.0
        return float(statistics.variance(cleaned))
    if stat == "median":
        return float(statistics.median(cleaned))
    if stat == "min":
        return float(min(cleaned))
    if stat == "max":
        return float(max(cleaned))
    if stat == "range":
        return float(max(cleaned) - min(cleaned))
    if stat == "iqr":
        ordered = sorted(cleaned)
        return float(linear_quantile(ordered, 0.75) - linear_quantile(ordered, 0.25))
    if stat.startswith("p") and stat[1:].isdigit():
        ordered = sorted(cleaned)
        prob = float(int(stat[1:])) / 100.0
        return float(linear_quantile(ordered, prob))

    raise ValueError(f"Unsupported statistic requested in ARS: {stat}")


def evaluate_population_where(where: str, row: Mapping[str, object]) -> bool:
    if not where.strip():
        return True

    try:
        expression = ast.parse(where, mode="eval")
    except SyntaxError as exc:  # pragma: no cover - defensive path
        raise PopulationExpressionError(str(exc)) from exc

    def _eval(node: ast.AST) -> object:
        if isinstance(node, ast.Expression):
            return _eval(node.body)
        if isinstance(node, ast.BoolOp):
            values = [_eval(value) for value in node.values]
            if isinstance(node.op, ast.And):
                return all(values)
            if isinstance(node.op, ast.Or):
                return any(values)
            raise PopulationExpressionError("Unsupported boolean operator")
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.Not):
            return not bool(_eval(node.operand))
        if isinstance(node, ast.Compare):
            left = _eval(node.left)
            results: List[bool] = []
            current = left
            for operator_node, comparator in zip(node.ops, node.comparators):
                right = _eval(comparator)
                if isinstance(operator_node, ast.Eq):
                    results.append(current == right)
                elif isinstance(operator_node, ast.NotEq):
                    results.append(current != right)
                elif isinstance(operator_node, ast.Gt):
                    results.append(float(current) > float(right))
                elif isinstance(operator_node, ast.GtE):
                    results.append(float(current) >= float(right))
                elif isinstance(operator_node, ast.Lt):
                    results.append(float(current) < float(right))
                elif isinstance(operator_node, ast.LtE):
                    results.append(float(current) <= float(right))
                else:  # pragma: no cover - unsupported operator guard
                    raise PopulationExpressionError("Unsupported comparison operator")
                current = right
            return all(results)
        if isinstance(node, ast.Name):
            return row.get(node.id)
        if isinstance(node, ast.Constant):
            return node.value
        raise PopulationExpressionError("Unsupported expression in population filter")

    result = _eval(expression)
    return bool(result)


def load_datasets(data_dir: Path) -> Dict[str, List[MutableMapping[str, object]]]:
    datasets: Dict[str, List[MutableMapping[str, object]]] = {}
    for csv_path in sorted(data_dir.glob("*.csv")):
        with csv_path.open(newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            datasets[csv_path.stem] = [dict(row) for row in reader]
    if not datasets:
        raise FileNotFoundError(f"No CSV files were located in {data_dir}")
    return datasets


def ensure_grouping_variables(
    data_rows: Sequence[Mapping[str, object]],
    group_vars: Sequence[str],
    dataset_name: str,
) -> None:
    if not data_rows:
        return
    missing = [var for var in group_vars if var not in data_rows[0]]
    if missing:
        missing_list = ", ".join(missing)
        raise KeyError(
            f"Grouping variables not found in dataset '{dataset_name}': {missing_list}"
        )


def analysis_population_label(population: Mapping[str, object], where: str) -> str:
    if isinstance(population.get("label"), str) and population["label"].strip():
        return str(population["label"])
    if isinstance(population.get("id"), str) and population["id"].strip():
        return str(population["id"])
    return where if where.strip() else "All"


def iter_grouped_rows(
    rows: Sequence[Mapping[str, object]],
    group_vars: Sequence[str],
) -> Iterator[Tuple[Tuple[object, ...], List[Mapping[str, object]]]]:
    if not group_vars:
        yield tuple(), list(rows)
        return

    grouped: Dict[Tuple[object, ...], List[Mapping[str, object]]] = {}
    for row in rows:
        key = tuple(row.get(var) for var in group_vars)
        grouped.setdefault(key, []).append(row)
    for key, group_rows in grouped.items():
        yield key, group_rows


def summarise_analysis(
    analysis: Mapping[str, object],
    datasets: Mapping[str, Sequence[Mapping[str, object]]],
    root: Path,
) -> None:
    dataset_name = analysis.get("dataset")
    if not isinstance(dataset_name, str):
        raise ValueError("Analysis is missing a 'dataset' entry")
    if dataset_name not in datasets:
        available = ", ".join(sorted(datasets))
        raise KeyError(f"Dataset '{dataset_name}' not found in data directory. Available: {available}")

    rows = list(datasets[dataset_name])

    population = analysis.get("population") or {}
    where = str(population.get("where", ""))
    filtered_rows = [row for row in rows if evaluate_population_where(where, row)]
    if not filtered_rows:
        raise ValueError(
            f"Population filter for analysis '{analysis.get('analysis_id')}' produced an empty dataset"
        )

    pop_label = analysis_population_label(population, where)

    grouping = analysis.get("grouping") or []
    if isinstance(grouping, Mapping):
        grouping = [grouping]
    group_vars = [
        str(group.get("variable") or group.get("name") or "")
        for group in grouping
        if isinstance(group, Mapping)
    ]
    group_vars = [var for var in group_vars if var]

    ensure_grouping_variables(filtered_rows, group_vars, dataset_name)

    variables = analysis.get("variables") or []
    if isinstance(variables, Mapping):
        variables = [variables]
    if not variables:
        raise ValueError("Analysis is missing a 'variables' entry")

    methods = analysis.get("methods") or []
    if isinstance(methods, Mapping):
        methods = [methods]

    traceability = analysis.get("traceability") or {}

    output_rows: List[Dict[str, object]] = []

    for variable in variables:
        if not isinstance(variable, Mapping):
            continue
        var_name = variable.get("name")
        if not isinstance(var_name, str) or not var_name:
            raise ValueError("Analysis variable is missing a name")
        if filtered_rows and var_name not in filtered_rows[0]:
            raise KeyError(
                f"Variable '{var_name}' for analysis '{analysis.get('analysis_id')}' "
                f"not found in dataset '{dataset_name}'"
            )

        method = select_method_for_variable(methods, variable)
        stats = [normalise_stat_keyword(stat) for stat in collect_statistics(variable, method)]
        stats = list(dict.fromkeys(stats))  # preserve order, remove duplicates

        for group_key, group_rows in iter_grouped_rows(filtered_rows, group_vars):
            values = [safe_float(row.get(var_name)) for row in group_rows]
            total_rows = len(values)

            for stat in stats:
                stat_value = compute_statistic(values, stat)
                row: Dict[str, object] = {
                    "analysis_id": analysis.get("analysis_id"),
                    "dataset": dataset_name,
                    "variable": var_name,
                    "variable_label": variable.get("label"),
                    "population": pop_label,
                    "method": method_label(method),
                    "studyid": traceability.get("studyid"),
                    "sap_section": traceability.get("sap_section"),
                    "inputs_ver": traceability.get("inputs_version"),
                    "stat_name": stat.upper(),
                    "stat": stat_value,
                }

                for index, value in enumerate(group_key, start=1):
                    row[f"group{index}"] = group_vars[index - 1]
                    row[f"group{index}_level"] = value

                output_rows.append(row)

    if not output_rows:
        return

    group_cols = [f"group{idx}" for idx in range(1, len(group_vars) + 1)]
    group_level_cols = [f"group{idx}_level" for idx in range(1, len(group_vars) + 1)]
    ordered_cols = (
        ["analysis_id"]
        + group_cols
        + group_level_cols
        + [
            "variable",
            "variable_label",
            "stat_name",
            "stat",
            "dataset",
            "population",
            "method",
            "studyid",
            "sap_section",
            "inputs_ver",
        ]
    )

    # Ensure all rows have every ordered column.
    for row in output_rows:
        for column in ordered_cols:
            row.setdefault(column, None)

    output_path = root / f"ARD_{slugify(analysis.get('analysis_id') or dataset_name + '_SUMMARY')}.csv"
    with output_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=ordered_cols)
        writer.writeheader()
        for row in output_rows:
            writer.writerow(row)

    print(f"Wrote: {output_path}")


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--ars",
        dest="ars_path",
        type=Path,
        default=Path("ars.json"),
        help="Path to the ARS JSON specification (default: ./ars.json)",
    )
    parser.add_argument(
        "--data",
        dest="data_dir",
        type=Path,
        default=Path("data"),
        help="Directory containing CSV datasets (default: ./data)",
    )
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> None:
    args = parse_args(argv)
    root = Path.cwd()

    if not args.ars_path.exists():
        raise FileNotFoundError(f"Could not locate ARS file at {args.ars_path}")
    if not args.data_dir.exists():
        raise FileNotFoundError(f"Could not locate data directory at {args.data_dir}")

    with args.ars_path.open(encoding="utf-8") as handle:
        ars = json.load(handle)

    analyses = ars.get("analyses")
    if not isinstance(analyses, Sequence) or not analyses:
        raise ValueError(f"No analyses were found in {args.ars_path}")

    datasets = load_datasets(args.data_dir)

    for analysis in analyses:
        summarise_analysis(analysis, datasets, root)


if __name__ == "__main__":
    main()

