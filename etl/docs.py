"""Generate docs/data_dictionary.md from the database catalog.

Tables, views, columns, types and the COMMENTs written in the SQL files are
read from information_schema / pg_catalog, so the documentation can never
drift away from the actual database.
"""
from __future__ import annotations

from .config import ROOT
from .db import query_df

SCHEMAS = ["core", "mart", "stg", "ref"]

SQL = """
SELECT c.table_schema, c.table_name,
       CASE t.table_type WHEN 'VIEW' THEN 'view' ELSE 'table' END       AS kind,
       obj_description(format('%%I.%%I', c.table_schema, c.table_name)::regclass) AS table_comment,
       c.ordinal_position, c.column_name, c.data_type,
       col_description(format('%%I.%%I', c.table_schema, c.table_name)::regclass, c.ordinal_position) AS column_comment
FROM information_schema.columns c
JOIN information_schema.tables t
  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
WHERE c.table_schema = ANY(%s::text[])
ORDER BY array_position(%s::text[], c.table_schema::text), c.table_name, c.ordinal_position
"""


def write_data_dictionary(conn) -> None:
    df = query_df(conn, SQL, (SCHEMAS, SCHEMAS))
    df = df.astype(object).where(df.notna(), None)   # NULL comments -> None, not NaN
    lines = ["# Data dictionary", "",
             "_Generated from the database catalog by `python pipeline.py docs` - do not edit by hand._", ""]
    for schema in SCHEMAS:
        part = df[df.table_schema == schema]
        if part.empty:
            continue
        lines += [f"## Schema `{schema}`", ""]
        for (table, kind), cols in part.groupby(["table_name", "kind"], sort=False):
            comment = cols.table_comment.iloc[0]
            lines += [f"### `{schema}.{table}` ({kind})", ""]
            if comment:
                lines += [comment, ""]
            lines += ["| # | Column | Type | Description |", "|---|---|---|---|"]
            for r in cols.itertuples():
                desc = (r.column_comment or "").replace("|", "\\|").replace("\n", " ")
                lines.append(f"| {r.ordinal_position} | `{r.column_name}` | {r.data_type} | {desc} |")
            lines.append("")
    out = ROOT / "docs" / "data_dictionary.md"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"  docs/data_dictionary.md ({df.groupby(['table_schema', 'table_name']).ngroups} objects)")
