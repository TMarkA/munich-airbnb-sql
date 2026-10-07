"""Turn an original Inside Airbnb download into the privacy-reduced copy kept in git.

Inside Airbnb publishes host names, profile texts, photos and the full text
of every review. The analysis needs none of it, so - following the GDPR
principle of data minimisation - these columns are removed before the files
are committed:

    data/downloads/<snapshot>/*.csv.gz   (original, git-ignored)
        -> data/<snapshot>/*.csv.gz      (reduced, committed)

Identifiers (listing_id, host_id, reviewer_id) are kept: they are needed for
joins and are already pseudonymous numbers.
"""
from __future__ import annotations

import csv
import gzip
import shutil
import sys

from .config import DATA_DIR, DOWNLOADS_DIR

DROP = {
    "listings": {"listing_url", "scrape_id", "source", "description", "neighborhood_overview", "picture_url",
                 "host_url", "host_profile_id", "host_profile_url", "host_name", "host_location", "host_about",
                 "host_thumbnail_url", "host_picture_url", "host_neighbourhood", "price_quote_raw",
                 "amenities_raw"},
    "reviews": {"reviewer_name", "comments"},
    "calendar": set(),
}


def prepare_snapshot(snapshot: str) -> None:
    src_dir, dst_dir = DOWNLOADS_DIR / snapshot, DATA_DIR / snapshot
    if not src_dir.exists():
        raise SystemExit(f"No downloads found in {src_dir}")
    dst_dir.mkdir(parents=True, exist_ok=True)
    csv.field_size_limit(sys.maxsize if sys.maxsize < 2**31 else 2**31 - 1)
    for name, drop in DROP.items():
        src, dst = src_dir / f"{name}.csv.gz", dst_dir / f"{name}.csv.gz"
        with gzip.open(src, "rt", encoding="utf-8", newline="") as fin, \
             gzip.open(dst, "wt", encoding="utf-8", newline="", compresslevel=9) as fout:
            reader = csv.reader(fin)
            header = next(reader)
            keep = [i for i, col in enumerate(header) if col not in drop]
            writer = csv.writer(fout, lineterminator="\n")
            writer.writerow([header[i] for i in keep])
            rows = 0
            for row in reader:
                writer.writerow([row[i] for i in keep])
                rows += 1
        print(f"  {dst.relative_to(DATA_DIR.parent)}: {rows:,} rows, {len(keep)} of {len(header)} columns "
              f"({dst.stat().st_size / 1e6:.1f} MB)")
    shutil.copy(src_dir / "neighbourhoods.geojson", dst_dir / "neighbourhoods.geojson")
    print(f"  {(dst_dir / 'neighbourhoods.geojson').relative_to(DATA_DIR.parent)} copied")
