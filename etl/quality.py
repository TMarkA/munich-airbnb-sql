"""Run the data-quality checks in sql/04_quality/ and save a report.

Each query in the file returns one row (check_name, problem_rows,
checked_rows, rule). The results are printed, saved to
results/00_quality_checks.csv, and the step fails if a 'must be 0' check
finds problems.
"""
from __future__ import annotations

import pandas as pd

from .config import RESULTS_DIR, SQL_DIR
from .db import query_df


def run_checks(conn) -> int:
    results = []
    for path in sorted((SQL_DIR / "04_quality").glob("*.sql")):
        for statement in path.read_text(encoding="utf-8").split(";"):
            if "SELECT" in statement.upper():
                results.append(query_df(conn, statement))
    df = pd.concat(results, ignore_index=True)

    failed = 0
    for r in df.itertuples():
        bad = r.rule == "must be 0" and r.problem_rows > 0
        failed += bad
        status = "FAIL" if bad else ("ok" if r.rule == "must be 0" else "info")
        print(f"  [{status:<4}] {r.check_name:<68} {r.problem_rows:>7,} of {r.checked_rows:,}")
    RESULTS_DIR.mkdir(exist_ok=True)
    df.to_csv(RESULTS_DIR / "00_quality_checks.csv", index=False)
    print(f"  -> {len(df)} checks, {failed} failed  (results/00_quality_checks.csv)")
    return 1 if failed else 0
