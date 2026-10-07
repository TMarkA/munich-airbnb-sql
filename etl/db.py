"""Small helpers around psycopg2: connect, run SQL files, query to DataFrame."""
from __future__ import annotations

from contextlib import contextmanager
from pathlib import Path

import psycopg2

from .config import DB


@contextmanager
def connect(autocommit: bool = False):
    """Open a connection and always close it again."""
    conn = psycopg2.connect(**DB)
    conn.set_client_encoding("UTF8")   # Windows clients may default to WIN1252
    conn.autocommit = autocommit
    try:
        yield conn
        if not autocommit:
            conn.commit()
    except Exception:
        if not autocommit:
            conn.rollback()
        raise
    finally:
        conn.close()


def run_sql_file(conn, path: Path) -> None:
    """Execute every statement in a .sql file (psycopg2 accepts multi-statement strings)."""
    sql = path.read_text(encoding="utf-8")
    with conn.cursor() as cur:
        cur.execute(sql)


def run_sql_folder(conn, folder: Path) -> list[str]:
    """Run all .sql files of a folder in alphabetical order (the numeric prefix sets the order)."""
    done = []
    for path in sorted(folder.glob("*.sql")):
        run_sql_file(conn, path)
        done.append(path.name)
    return done


def query_df(conn, sql: str, params=None):
    """Run a SELECT and return a pandas DataFrame."""
    import pandas as pd

    with conn.cursor() as cur:
        cur.execute(sql, params)
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
    return pd.DataFrame(rows, columns=cols)
