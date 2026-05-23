# Plan Overview

Phased delivery for Expensy, derived directly from `design/Expensy.html` (Dashboard, Add Expense, Transactions, Analytics).

## Design summary

- **Frame**: 390 × 844 (mobile-only, portrait).
- **Palette**: blue `#1B45D0` (primary, hero gradient), orange `#F56B1E` (CTA/accent), bg `#EEF3FF`, card white, success `#16A34A`, danger `#DC2626`, plus per-category tints (purple, pink, teal).
- **Typography**: DM Sans 300/400/500/600/700.
- **Nav**: bottom bar with `home / list / [add+] / chart` (4 tabs, center `+` is the Add Expense entry).
- **Categories (seeded)**: Food, Travel, Shop, Health, Fun, Home (each has a 2-letter abbreviation and a color).
- **Sample currency**: USD; values shown to 2 decimals.

## Phase map

| # | File | Scope |
|---|------|-------|
| 01 | `01-foundations.md`   | Repo bootstrap — Node.js API skeleton, Flutter app skeleton, design tokens, CI |
| 02 | `02-auth.md`          | Signup/login on backend, secure token storage + login screens on Flutter |
| 03 | `03-dashboard.md`     | `/me/summary` + `/transactions/recent` + Dashboard screen with hero balance & budget bar |
| 04 | `04-add-expense.md`   | `POST /transactions` + categories endpoint + numpad screen + success state |
| 05 | `05-transactions.md`  | `/transactions?month=` (grouped) + monthly summary + Transactions screen with month nav |
| 06 | `06-analytics.md`     | `/analytics?month=` (category breakdown) + donut chart + horizontal bars |
| 07 | `07-polish-release.md`| Offline cache, error/empty states, accessibility, store metadata, CI release flow |

## Cross-cutting principles

- **Design fidelity first.** Every Flutter screen must reproduce the corresponding HTML artboard pixel-faithfully on a 390 logical-width device before adding extras.
- **Backend leads the contract.** Each phase ships the backend endpoint + OpenAPI before the Flutter screen consumes it. No client-only mocks past Phase 02.
- **Vertical slices.** Each phase produces a runnable end-to-end demo of the screen it owns. No "back-end only" or "UI only" phases after foundations.
- **One database, one currency** for v1. Multi-currency, multi-wallet, recurring transactions, savings goals, notifications are explicitly **out of scope** for these phases — record them in a backlog if surfaced.

## Out of scope for v1

Recurring subscriptions, savings goals + milestones, push notifications, multi-wallet, multi-currency, shared/household budgets, receipt OCR, web client. The data model should not preclude them, but no UI is built.
