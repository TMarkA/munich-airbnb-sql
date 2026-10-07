"""Load one Inside Airbnb snapshot into the raw schema of PostgreSQL.

* Each raw table is dropped and created again from the header row of its
  file, with every column as TEXT. Converting types is the job of the SQL
  staging layer, where problems are visible.
* Files are streamed into PostgreSQL with COPY straight from the .gz file;
  the CSV parser handles quoted fields with commas and line breaks.
* District polygons (GeoJSON) are stored with their area in km², computed
  here so no GIS extension is needed.
"""
from __future__ import annotations

import gzip
import json
import math
import re

from .config import DATA_DIR, DOWNLOADS_DIR

FILES = ["listings", "calendar", "reviews"]


def _clean(col: str) -> str:
    """Column names in lower case with underscores only."""
    return re.sub(r"[^a-z0-9_]", "_", col.strip().lower())


def _polygon_area_km2(rings) -> float:
    """Area of one polygon (outer ring minus holes) on a local flat projection."""
    def ring_area(ring):
        lat0 = math.radians(sum(p[1] for p in ring) / len(ring))
        pts = [(p[0] * 111.320 * math.cos(lat0), p[1] * 110.574) for p in ring]
        return abs(sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(pts, pts[1:] + pts[:1]))) / 2
    return ring_area(rings[0]) - sum(ring_area(h) for h in rings[1:])


def load_snapshot(conn, snapshot: str, use_downloads: bool = False) -> None:
    src = (DOWNLOADS_DIR if use_downloads else DATA_DIR) / snapshot
    if not src.exists():
        raise SystemExit(f"Snapshot folder not found: {src}")

    with conn.cursor() as cur:
        for name in FILES:
            path = src / f"{name}.csv.gz"
            with gzip.open(path, "rb") as fh:
                header = [_clean(c) for c in fh.readline().decode("utf-8").rstrip("\r\n").split(",")]
            columns = ", ".join(f'"{c}" text' for c in header)
            cur.execute(f"DROP TABLE IF EXISTS raw.{name} CASCADE")
            cur.execute(f"CREATE TABLE raw.{name} ({columns})")
            with gzip.open(path, "rb") as fh:
                cur.copy_expert(f"COPY raw.{name} FROM STDIN WITH (FORMAT csv, HEADER true)", fh)
            cur.execute(f"SELECT COUNT(*) FROM raw.{name}")
            print(f"  raw.{name:<9} {cur.fetchone()[0]:>10,} rows  {len(header):>3} columns")

        # district polygons
        geo = json.loads((src / "neighbourhoods.geojson").read_text(encoding="utf-8"))
        cur.execute("TRUNCATE raw.neighbourhoods")
        for feat in geo["features"]:
            geom = feat["geometry"]
            polys = geom["coordinates"] if geom["type"] == "MultiPolygon" else [geom["coordinates"]]
            area = sum(_polygon_area_km2(p) for p in polys)
            cur.execute("INSERT INTO raw.neighbourhoods (neighbourhood, area_km2, geometry) VALUES (%s, %s, %s)",
                        (feat["properties"]["neighbourhood"], round(area, 3), json.dumps(geom)))
        print(f"  raw.neighbourhoods {len(geo['features']):>6} districts")
    conn.commit()
