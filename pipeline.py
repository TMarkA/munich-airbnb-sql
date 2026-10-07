"""Command-line entry point for the Munich Airbnb warehouse.

Examples
--------
    python pipeline.py all                              # build everything from data/2026-06-29
    python pipeline.py prepare --snapshot 2026-09-28    # strip personal data from a new download
    python pipeline.py all --snapshot 2026-09-28        # rebuild everything from the new snapshot
    python pipeline.py test                             # data-quality checks only
"""
from __future__ import annotations

import argparse
import sys
import time

from etl import analyze, load, quality, transform
from etl.config import DEFAULT_SNAPSHOT
from etl.db import connect


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Munich Airbnb warehouse (PostgreSQL)")
    parser.add_argument("step", choices=["prepare", "setup", "load", "transform", "test",
                                         "analyze", "charts", "docs", "all"])
    parser.add_argument("--snapshot", default=DEFAULT_SNAPSHOT,
                        help="snapshot folder in data/, e.g. 2026-06-29")
    parser.add_argument("--from-downloads", action="store_true",
                        help="load the original files in data/downloads/ instead of the reduced copies")
    args = parser.parse_args(argv)
    start = time.time()

    if args.step == "prepare":
        from etl.prepare_data import prepare_snapshot
        print(f"\n== prepare {args.snapshot}")
        prepare_snapshot(args.snapshot)
        return 0

    steps = ["setup", "load", "transform", "test", "analyze", "charts", "docs"] if args.step == "all" else [args.step]
    exit_code = 0
    with connect() as conn:
        for step in steps:
            print(f"\n== {step} " + "=" * (60 - len(step)))
            if step == "setup":
                transform.setup(conn)
            elif step == "load":
                print(f"  snapshot {args.snapshot}")
                load.load_snapshot(conn, args.snapshot, use_downloads=args.from_downloads)
            elif step == "transform":
                transform.transform(conn)
            elif step == "test":
                exit_code = max(exit_code, quality.run_checks(conn))
            elif step == "analyze":
                analyze.run_analyses(conn)
            elif step == "charts":
                from etl import charts
                charts.make_charts()
            elif step == "docs":
                from etl import docs
                docs.write_data_dictionary(conn)
    print(f"\nfinished in {time.time() - start:.0f} s")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
