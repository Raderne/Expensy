# Phase 04 — Add Expense

Build Screen 02 end-to-end. Most interactive screen in v1.

## Design references

`design/Expensy.html` lines 242–340 (`AddScreen`). Components:
- Back button + "Add Expense" title (no `StatusBar.light` here — dark icons on light bg).
- Centered amount display: `$` (26 / 400 / inkMid) + value (52 / 700 / ink, letter-spacing -2), 72×2.5 blue underline.
- Category grid: 3 columns × 2 rows, selected card flips to solid `category.color` with white text.
- Note input (single-line, placeholder "What was this for?").
- Numpad: 4 rows × 3 cols, last row `[. 0 ⌫]`. `⌫` cell uses `blueLight` background + `blue` text.
- Save button: disabled (`inkFaint`) when amount is 0; otherwise orange with elevation `0 4 16 orange@27%`.
- Success state: green check tile (76×76, radius 24, `greenLight` bg), "Expense Saved!" heading, `-$X · {Category}` subtitle, "Add Another" orange pill.

## Numpad rules (from design source)

- Tapping a digit on `'0'` replaces it (no leading zeros).
- `.` only allowed once.
- Cap at 2 decimal places.
- `⌫` decrements; collapses to `'0'` if string would become empty.
- Save is a no-op if `parseFloat(val) <= 0`.

Port these rules verbatim — they're product behavior, not just UI.

## Backend

### Endpoints

- `POST /transactions` — body `{categoryId, amount, note?, occurredAt?}`. `occurredAt` defaults to `now()`. Stores `amount` negative for expenses (the only kind this screen creates; income is created server-side via a future import flow).
- (Already shipped) `GET /categories`.

### Validation

```ts
z.object({
  categoryId: z.string().cuid(),
  amount: z.number().positive().max(1_000_000),    // client sends positive; server negates
  note: z.string().max(140).optional(),
  occurredAt: z.string().datetime().optional(),
})
```

Return the created transaction (joined with category) so the client can optimistic-update the Dashboard cache.

## Frontend

1. `features/add_expense/presentation/add_expense_screen.dart` — single `StatefulWidget` or Riverpod `Notifier` that holds `amount`, `categoryKey`, `note`, `saving`, `saved` (mirror the React state).
2. `Numpad` widget — 4×3 GridView with fixed 44 height per cell; do **not** use a system keyboard.
3. `CategoryGrid` widget driven by the `categories` provider from Phase 03.
4. `SuccessSheet` widget for the post-save state. Auto-dismiss on "Add Another"; on bottom-nav tap navigate away normally.
5. On successful POST: invalidate Dashboard, Transactions, and Analytics providers so they refetch on next visit.
6. Haptic feedback (`HapticFeedback.lightImpact`) on digit press and `mediumImpact` on save success.

## Exit criteria

- Entering `12.99`, picking Food, typing "Coffee", saving → row appears on Dashboard after navigating back, and on Transactions when that tab is visited.
- Save is visibly disabled at amount 0.
- Decimal/leading-zero/backspace rules match the HTML reference exactly.
