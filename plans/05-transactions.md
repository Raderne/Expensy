# Phase 05 — Transactions

Build Screen 03 end-to-end.

## Design references

`design/Expensy.html` lines 342–406 (`TransactionsScreen`). Components:
- "Transactions" title (22 / 700) + filter icon button top-right (3 stacked bars, decreasing width).
- Month nav: `‹` / `Month YYYY` (15 / 700, centered) / `›`. In the source, prev/next clamp within `[March, April, May]` 2026; in production they navigate to the user's actual transaction history range.
- Two summary cards side-by-side: Income (greenLight bg, green text, `+$5,200`) and Expenses (redLight bg, red text, `-$2,890`). Values come from the selected month.
- Grouped list: each group has an uppercase muted date label ("TODAY", "YESTERDAY", "MAY 21", "MAY 20") followed by `TxRow`s.

## Backend

### Endpoints

- `GET /transactions?month=YYYY-MM&categoryId=&type=income|expense&cursor=` — paginated (cursor on `(occurredAt desc, id desc)`, page size 30). Returns transactions joined with category, ordered newest first.
- `GET /me/summary?month=YYYY-MM` — already exists; reuse for the two summary cards.
- `GET /me/transaction-months` — distinct `YYYY-MM` values for the user's transactions, newest first. Drives the month nav range.

### Notes

- Group server-side? No. Return flat list; the client groups by `Today / Yesterday / MMM d` to match the design's display.
- The filter icon in the design has no panel yet — wire it to a bottom sheet stub (`"Filters coming soon"`) so the affordance is honored but no extra UI is built.

## Frontend

1. `features/transactions/data/transactions_repository.dart` — list + months.
2. `features/transactions/application/transactions_controller.dart` — keeps `{month, filters, pages}`. Uses `AsyncNotifier` with cursor-based infinite scroll.
3. `MonthNav` widget — disables `‹` / `›` when at the edge of `transaction-months`.
4. `SummaryRow` widget (green / red cards).
5. Grouped list: a `CustomScrollView` of `SliverList`s. Group key uses local time zone.
6. Date label formatting:
   - `Today` if `occurredAt` is today.
   - `Yesterday` if exactly one day ago.
   - Else `MMM d` (e.g., "May 21"). Uppercase via TextStyle.
7. Empty state per month: muted illustration + "No transactions in {Month}".

## Exit criteria

- Newly-created transaction from Phase 04 appears under "Today" without a manual refresh (provider was invalidated).
- Month nav advances/retreats and the summary cards + list update accordingly.
- Scrolling past 30 transactions loads the next page.
