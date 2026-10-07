"""Central configuration: paths and database settings.

Database credentials are read from environment variables (or a local .env file,
which is git-ignored). Nothing secret is stored in the repository.
"""
from __future__ import annotations

import os
from pathlib import Path

try:  # python-dotenv is optional; plain environment variables work too
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover
    load_dotenv = None

ROOT = Path(__file__).resolve().parent.parent
if load_dotenv:
    load_dotenv(ROOT / ".env")

SQL_DIR = ROOT / "sql"
ANALYSIS_DIR = ROOT / "analysis"
REF_DIR = ROOT / "ref"
DATA_DIR = ROOT / "data"                       # data/<snapshot>/ = privacy-reduced files (committed)
DOWNLOADS_DIR = DATA_DIR / "downloads"         # original Inside Airbnb files (git-ignored)
RESULTS_DIR = ROOT / "results"
IMAGES_DIR = ROOT / "docs" / "images"

DB = {
    "host": os.getenv("PGHOST", "localhost"),
    "port": int(os.getenv("PGPORT", "5432")),
    "dbname": os.getenv("PGDATABASE", "munich_airbnb"),
    "user": os.getenv("PGUSER", "postgres"),
    "password": os.getenv("PGPASSWORD", ""),
}

DEFAULT_SNAPSHOT = "2026-06-29"
