"""Create the README charts.

Charts 1, 3 and 4 are drawn from the CSV files in results/ (so every number
traces back to an analysis query). Chart 2 needs one value per night and
reads the mart view mart.calendar_daily directly.
"""
from __future__ import annotations

import matplotlib

matplotlib.use("Agg")
import matplotlib.dates as mdates  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
import pandas as pd  # noqa: E402

from .config import IMAGES_DIR, RESULTS_DIR  # noqa: E402
from .db import connect, query_df  # noqa: E402

SURFACE, INK, INK2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e6e5e1"
BLUE, ORANGE, RED, LIGHT = "#2a78d6", "#eb6834", "#e34948", "#b7d3f6"


def _style(ax, title, subtitle, grid_axis="y"):
    ax.set_facecolor(SURFACE)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_color(GRID)
    ax.tick_params(colors=INK2, labelsize=10, length=0)
    getattr(ax, f"{grid_axis}axis").grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.set_title(title, loc="left", fontsize=14, fontweight="bold", color=INK, pad=28)
    ax.text(0, 1.02, subtitle, transform=ax.transAxes, fontsize=10, color=INK2)


def _save(fig, name):
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    fig.savefig(IMAGES_DIR / name, dpi=200, bbox_inches="tight", facecolor=SURFACE)
    plt.close(fig)
    print(f"  docs/images/{name}")


def make_charts() -> None:
    # 1 - demand trend (reviews per year)
    d = pd.read_csv(RESULTS_DIR / "05_demand_trend.csv")
    d = d[~d.partial_year.astype(str).str.lower().isin(["true", "t"])]
    fig, ax = plt.subplots(figsize=(10, 4.6), facecolor=SURFACE)
    colors = [RED if y == 2020 else BLUE for y in d.year]
    ax.bar(d.year.astype(str), d.reviews, color=colors, width=0.62)
    for x, (y, v, idx) in enumerate(zip(d.year, d.reviews, d.index_2019_100)):
        ax.text(x, v + 700, f"{v / 1000:.1f}k", ha="center", fontsize=9, color=INK)
    ax.yaxis.set_major_formatter(lambda v, _: f"{v / 1000:.0f}k")
    _style(ax, "Airbnb demand in Munich: reviews per year",
           "COVID halved demand in 2020; by 2025 it was 2.8x the 2019 level · reviews as a proxy for stays")
    _save(fig, "01_demand_trend.png")

    # 2 - Oktoberfest in the forward calendar (daily, all room types)
    with connect() as conn:
        cal = query_df(conn, """
            SELECT night, SUM(share_unavailable * listings) / SUM(listings) AS share
            FROM mart.calendar_daily
            WHERE night BETWEEN DATE '2026-08-01' AND DATE '2026-11-30'
            GROUP BY night ORDER BY night""")
        okt = query_df(conn, "SELECT start_date, end_date FROM ref.oktoberfest WHERE year = 2026")
    cal["night"] = pd.to_datetime(cal.night)
    fig, ax = plt.subplots(figsize=(10, 4.4), facecolor=SURFACE)
    s, e = pd.to_datetime(okt.start_date[0]), pd.to_datetime(okt.end_date[0])
    ax.axvspan(s, e + pd.Timedelta(days=1), color=LIGHT, alpha=0.6, linewidth=0)
    ax.text(s + (e - s) / 2, 0.81, "Oktoberfest\n19 Sep - 4 Oct", ha="center", fontsize=9.5, color=INK)
    ax.plot(cal.night, cal.share.astype(float), color=BLUE, linewidth=2)
    ax.set_ylim(0.45, 0.85)
    ax.yaxis.set_major_formatter(lambda v, _: f"{v:.0%}")
    ax.xaxis.set_major_locator(mdates.MonthLocator())
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
    _style(ax, "Share of Airbnb nights already taken, autumn 2026",
           "Booked or blocked nights per day, as seen in the calendar scraped on 29 June 2026")
    _save(fig, "02_oktoberfest_calendar.png")

    # 3 - host types: share of listings vs share of revenue
    d = pd.read_csv(RESULTS_DIR / "04_host_concentration.csv")
    labels = [t.split(" ", 1)[1] for t in d.host_type]
    fig, ax = plt.subplots(figsize=(10, 4.2), facecolor=SURFACE)
    y = range(len(d))
    h = 0.36
    ax.barh([i + h / 2 for i in y], d.pct_listings, height=h, color=BLUE, label="% of listings")
    ax.barh([i - h / 2 for i in y], d.pct_est_revenue, height=h, color=ORANGE, label="% of estimated revenue")
    for i, (a, b) in enumerate(zip(d.pct_listings, d.pct_est_revenue)):
        ax.text(a + 0.8, i + h / 2, f"{a:.0f}%", va="center", fontsize=9.5, color=INK)
        ax.text(b + 0.8, i - h / 2, f"{b:.0f}%", va="center", fontsize=9.5, color=INK)
    ax.set_yticks(list(y))
    ax.set_yticklabels(labels)
    ax.invert_yaxis()
    ax.set_xlim(0, 80)
    ax.xaxis.set_major_formatter(lambda v, _: f"{v:.0f}%")
    ax.legend(frameon=False, loc="lower right", fontsize=10)
    _style(ax, "Professional hosts: 14% of listings, 30% of revenue",
           "Hosts by number of Munich listings (single / 2-4 / 5+) · revenue estimated from reviews x price",
           grid_axis="x")
    _save(fig, "03_host_types.png")

    # 4 - the 8-week rule
    d = pd.read_csv(RESULTS_DIR / "10_rule_of_56_nights.csv")
    labels = [t.split(" ", 1)[1] if t[0].isdigit() else "All hosts" for t in d.host_type]
    fig, ax = plt.subplots(figsize=(10, 3.9), facecolor=SURFACE)
    colors = [BLUE] * (len(d) - 1) + [INK2]
    ax.barh(labels, d.pct_above_56_nights, color=colors, height=0.55)
    for i, (v, n) in enumerate(zip(d.pct_above_56_nights, d.above_56_nights)):
        ax.text(v + 0.8, i, f"{v:.0f}%  ({n:,} homes)", va="center", fontsize=9.5, color=INK)
    ax.invert_yaxis()
    ax.set_xlim(0, 75)
    ax.xaxis.set_major_formatter(lambda v, _: f"{v:.0f}%")
    _style(ax, "Entire homes estimated above Munich's 56-night limit",
           "Active entire homes with more than 8 weeks of estimated bookings per year (permit required)",
           grid_axis="x")
    _save(fig, "04_rule_56_nights.png")


if __name__ == "__main__":
    make_charts()
