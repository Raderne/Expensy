# Phase 06 — Analytics

Build Screen 04 end-to-end.

## Design references

`design/Expensy.html` lines 408–482 (`AnalyticsScreen`). Components:
- Title "Analytics" + month chip ("May 2026") with `border` outline (no nav arrows — tap opens a month picker bottom sheet).
- Donut + legend row:
  - SVG donut, radius 50, stroke width 13, ring color `border`. Segments rendered as `strokeDasharray = "${len-2.5} ${circumference}"` rotated by `(cum/Circ)*360 - 90`. The 2.5 gap is intentional spacing between segments.
  - Center label: "Total" (11 / inkMid) + total amount (20 / 700 / ink).
  - Legend: dot + label + percent per category, vertical stack.
- "Spending Breakdown" section title (15 / 700).
- Horizontal bars: dot + label (13 / 500) on left, amount (13 / 700) on right, full-width bar below (`border` track, category-colored fill, height 6, radius 3).

## Backend

### Endpoint

- `GET /analytics?month=YYYY-MM` →
  ```jsonc
  {
    "month": "2026-05",
    "total": 1408.69,
    "breakdown": [
      { "categoryId": "...", "label": "Shopping", "color": "#7C3AED", "amount": 624.50, "pct": 0.4434 },
      ...
    ]
  }
  ```
  Only expense rows (`amount < 0`). Sort by `amount` desc. Include zero-amount categories? **No** — match the design which only lists categories with spend. Round `pct` to 4 decimals.

### Implementation

Single `GROUP BY` on `(category_id)` filtered by user + month + `amount < 0`. Don't compute on the client.

## Frontend

1. `features/analytics/data/analytics_repository.dart`.
2. `features/analytics/application/analytics_controller.dart` — keyed by month so switching months caches per-month responses.
3. `DonutChart` widget — `CustomPainter` that mirrors the SVG math from the design source (R=50, SW=13, gap=2.5, start at -90°). Animate `sweepAngle` from 0 to target on first build (250 ms ease-out).
4. `SpendingBars` widget — column of bar rows. Width animates from 0 → `pct` on first build.
5. Month chip opens a `ModalBottomSheet` listing `transaction-months` (reuse the Phase 05 endpoint). Selecting one updates the controller.
6. Empty state: gray donut + "No expenses in {Month}".

## Exit criteria

- Numbers match Phase 03 totals for the same month (cross-check).
- Donut segments visually align with legend percentages.
- Switching months refetches and updates the chart without rebuilding the screen.
