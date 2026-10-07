"""Create the database objects and run the SQL transformation layers."""
from __future__ import annotations

import csv

from .config import REF_DIR, SQL_DIR
from .db import run_sql_folder

LAYERS = ["01_staging", "02_core", "03_mart"]
COUNTS = ["stg.listings", "stg.calendar", "stg.reviews", "core.dim_listing", "core.dim_host",
          "core.dim_district", "core.dim_date", "core.fact_listing_snapshot", "core.fact_calendar",
          "core.fact_review", "mart.listings"]


def setup(conn) -> None:
    """Create the schemas and reference tables, and load ref/*.csv."""
    for name in run_sql_folder(conn, SQL_DIR / "00_setup"):
        print(f"  ran {name}")
    with conn.cursor() as cur:            # reload reference CSVs (single source of truth: ref/)
        for path in sorted(REF_DIR.glob("*.csv")):
            with open(path, newline="", encoding="utf-8") as fh:
                header = next(csv.reader(fh))
                fh.seek(0)
                cur.execute(f"TRUNCATE ref.{path.stem}")
                cur.copy_expert(f"COPY ref.{path.stem} ({', '.join(header)}) FROM STDIN WITH (FORMAT csv, HEADER true)", fh)
            print(f"  ref.{path.stem} loaded")
    conn.commit()


def transform(conn) -> None:
    """Rebuild staging, core and mart (full refresh, in dependency order)."""
    for layer in LAYERS:
        for name in run_sql_folder(conn, SQL_DIR / layer):
            print(f"  {layer}/{name}")
    conn.commit()
    with conn.cursor() as cur:
        for table in COUNTS:
            cur.execute(f"SELECT COUNT(*) FROM {table}")
            print(f"  {table:<26} {cur.fetchone()[0]:>10,} rows")
