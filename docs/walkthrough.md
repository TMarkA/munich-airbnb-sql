# Walkthrough

How the project works, in the order the pipeline runs, plus the questions an interviewer is likely to ask.

## 1. `python pipeline.py all`

[`pipeline.py`](../pipeline.py) runs **setup → load → transform → test → analyze → charts → docs** in one database connection. Python only moves files and runs the SQL files in order; all cleaning, modelling and analysis is SQL. Credentials come from a git-ignored `.env` file.

## 2. Setup - [`sql/00_setup/`](../sql/00_setup/)

Creates one schema per layer (`raw`, `ref`, `stg`, `core`, `mart`) and two reference tables: the published Oktoberfest dates (`INSERT ... VALUES`) and the official district names (loaded from `ref/districts.csv`).

## 3. Load - [`etl/load.py`](../etl/load.py)

- Each raw table is created from the header row of its file, with every column as text, and filled with PostgreSQL's `COPY` command. 2.5 million calendar rows load in a few seconds.
- District polygons are stored as text together with their area, computed in Python.

## 4. Transform - [`sql/01_staging`](../sql/01_staging/), [`02_core`](../sql/02_core/), [`03_mart`](../sql/03_mart/)

1. **Staging** converts text into proper types with `NULLIF` and `CAST`, cleans prices with `REPLACE`, sets amenity flags with `LIKE`, and joins `ref.districts` for the official names.
2. **Core** builds the star schema:
   - Dimensions: `dim_date` (one row per day, from `generate_series`, with an Oktoberfest flag via a `LEFT JOIN ... BETWEEN`), `dim_district`, `dim_host` (host type with `GROUP BY` and `CASE`) and `dim_listing`.
   - Facts with different grains: `fact_listing_snapshot` (one row per listing), `fact_calendar` (listing × night) and `fact_review` (one row per review).
   - Primary and foreign keys guarantee those grains. An `INNER JOIN` drops calendar rows of unknown listings; a `LEFT JOIN` keeps reviews of removed listings and flags them.
3. **Mart** is four views:
   - `mart.listings`: one wide row per listing, joining the fact with three dimensions, plus the occupancy model, estimated revenue and the 56-night flag. It is the Power BI source.
   - `mart.calendar_daily`, `mart.reviews_monthly` and `mart.district_summary` aggregate it further.

## 5. Test - [`sql/04_quality/400_quality_checks.sql`](../sql/04_quality/400_quality_checks.sql)

12 plain `SELECT` queries. Each returns the number of problem rows: six must be 0 (duplicates, unmapped districts, unconverted prices, coordinates, ratings, review dates), six document known properties of the data (missing prices, outliers, dropped calendar rows, …). The results are saved to `results/00_quality_checks.csv`.

## 6. Analyze, charts, docs

Each file in `analysis/` answers one question and is saved to `results/*.csv`. The charts are drawn from those CSVs, and `docs/data_dictionary.md` is generated from the comments in the database.

## SQL used, and where

| Technique | Example |
|---|---|
| `INNER`, `LEFT` and `CROSS JOIN` | `300_listings.sql`, `260_fact_review.sql`, analysis 07 |
| Self-join | analysis 08 (two medians side by side), `320_reviews_monthly.sql` (same month last year) |
| `GROUP BY`, `HAVING`, `COUNT(DISTINCT)` | analyses 01, 03, 12 |
| Conditional aggregation with `CASE WHEN` | almost every analysis |
| CTEs (`WITH`) | analyses 04, 05, 08, 09, 12 |
| Subqueries | analysis 01 (share of total), analysis 05 (2019 base), quality check 12 |
| `UNION ALL` | total rows (01, 10), stacked breakdowns (11) |
| Window functions | `RANK` (02), `LAG` (05), `SUM() OVER ()` for shares (04, 09), rolling 12 months (`320`) |
| Medians | `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ...)` |
| Views | the `mart` layer |
| Keys and constraints | every table in `core` |

## Likely interview questions

| Question | Answer |
|---|---|
| How do you measure demand without booking data? | Reviews as a proxy, plus the San Francisco model for nights; my SQL version matches Inside Airbnb's own estimate within 5 nights for 98% of listings. |
| Why is the Oktoberfest premium only an estimate? | Each listing has one price quote for one date. I compare Oktoberfest quotes with other quotes within the same room type and size, which controls the main drivers but not every listing difference. |
| What was the trickiest data issue? | Prices are quotes for different dates, so a naive average mixes Oktoberfest and normal nights. Also inconsistent district names and a few absurd prices. |
| Why medians and not averages for prices? | One listing quotes €78,531 a night. Medians aren't pulled by such values. |
| Why views in the mart layer? | They always show the current data after a reload and store nothing twice. Power BI reads them like tables. |
| Why remove names and review texts? | They aren't needed for the analysis; data minimisation is a GDPR principle and reduces risk when publishing. |
| How would you extend it? | Load several quarterly snapshots to track listings entering and leaving the market, and build the Power BI report on `mart`. |
