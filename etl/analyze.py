"""Run every query in analysis/ and save the result as results/<name>.csv.

The CSV files are committed to the repository, so readers can see the
answers on GitHub (which renders CSV files as tables) without running
anything.
"""
from __future__ import annotations

from .config import ANALYSIS_DIR, RESULTS_DIR
from .db import query_df


def run_analyses(conn) -> None:
    RESULTS_DIR.mkdir(exist_ok=True)
    for path in sorted(ANALYSIS_DIR.glob("*.sql")):
        df = query_df(conn, path.read_text(encoding="utf-8"))
        out = RESULTS_DIR / f"{path.stem}.csv"
        df.to_csv(out, index=False)
        print(f"  {path.name:<38} -> results/{out.name} ({len(df)} rows)")
