# Project Handover

Everything you need to pick this project up: current status, how to run it, what changed recently, and what's left. For a deep, teachable explanation of *how* the app works and *why* it's built this way, read [`concepts-and-architecture.md`](./concepts-and-architecture.md) alongside this doc — or [`simple-explanation.md`](./simple-explanation.md) for the same material in plain, no-jargon language.

---

## TL;DR

- **What it is**: a fully simulated stock trading app (10 stocks, mock live price feed, watchlists, buy/sell, holdings with live P&L, order history). No backend — everything runs and persists on-device.
- **Status**: feature-complete (Phases 0–5) plus a full UI modernization pass. Phase 6 (quality/tests/submission) is ~80% — see [Open items](#open-items).
- **Stack**: Flutter (Material 3), `flutter_bloc` for state management, `shared_preferences` for persistence, `get_it` for dependency injection. No backend, no charting library (sparklines are hand-rolled).

## How to run it

```bash
flutter pub get
flutter run              # picks a connected device/simulator
flutter run -d chrome     # or specifically run it as a web app, useful for quick UI checks
```

First launch seeds an empty **"My Watchlist"** and a **₹1,00,000** wallet balance.

## How to verify a change

```bash
flutter analyze     # static analysis — must be clean
flutter test         # 12 tests: unit + widget — must all pass
dart format lib test  # formatting
```

If you're changing anything UI-facing, also actually run it (`flutter run -d chrome` is fastest for quick visual checks) — `flutter analyze`/`flutter test` catch correctness bugs, not "does this look right."

---

## What's implemented

**Core features** (Phases 0–5, all complete — see [`phase-progress.md`](./phase-progress.md) for the detailed checklist):
- Live market overview for 10 fixed stocks, with a mock price feed running independently of any screen
- Multi-watchlist CRUD, drag-to-reorder, swipe-to-remove, duplicate-prevention
- Buy/sell order ticket with inline validation and a snapshot-once execution price
- Holdings with live P&L, sortable, weighted-average-cost tracking
- Full state persistence across restarts (wallet, watchlists, holdings, order history)

**Added this session** (UI modernization pass — see §"Recent work" below for the why/how):
- Dark mode (system/light/dark, persisted, one AppBar toggle)
- Sparkline mini-charts on every price row
- Search + sort on the Market tab
- A 4th tab: **Activity** — full order history, newest first
- A feed stop/resume button (freeze live prices, tap to resume)

## Recent work (this session)

Roughly in order:

1. **Flutter 3.47 upgrade fixes** — `ReorderableListView.onReorder` → `onReorderItem` (the old callback is deprecated and needed a manual index-adjustment that the new one already does internally).
2. **Phase 6 hardening** — added widget tests for the watchlist/ticket/holdings flows. Writing these tests *found* two real bugs (see below), which is exactly the value of widget tests over unit tests alone.
3. **Full UI redesign** — new Material 3 theme (light + dark, seeded palette), a `MarketColors` theme extension replacing ~15 duplicated hardcoded hex colors app-wide, sparklines, market search/sort, and the new Activity tab.
4. **Feed stop/resume button** — required threading a new capability through all three layers: `MarketRepository` interface → `MarketRepositoryImpl` → `MarketCubit` state → UI button. (The underlying mock feed already supported `stop()`; it just wasn't exposed above the data layer.)
5. **Two rounds of `/code-review`**, each followed by fixing everything confirmed real. See [Bugs found and fixed](#bugs-found-and-fixed).

## Bugs found and fixed

These are worth knowing about even though they're fixed — they're the kind of bug that reappears in similar forms if the underlying cause isn't understood:

| Bug | Root cause | Fix |
|---|---|---|
| Crash tapping a stock right after launch | `OrderBloc` force-unwrapped a nullable `tradingState` that's only populated after an async load | `OrderTicketPage.push()` guards on it; `OrderBloc` now requires a non-null `TradingState` at construction (compiler-enforced, not a runtime `!`) |
| Confirmation screen overflowed on short screens | Content column wasn't scrollable | Wrapped in `SingleChildScrollView`, action buttons pinned below |
| Market list could misattribute flash animations between stocks | List items had no `Key`, so Flutter reconciled by position — a problem once search/sort made list order dynamic | Added `key: ValueKey(symbol.value)` to each row |
| Switching Market sort mode could render one frame of stale prices | A `buildWhen` performance shortcut skipped updating `BlocBuilder`'s cached state; verified against `flutter_bloc`'s actual source | Removed the shortcut — rebuilding a 10-item list every tick is cheap enough that the "optimization" wasn't worth the correctness risk |
| A failed order (e.g. insufficient balance) permanently locked the ticket — no way to edit and retry | `OrderBloc` only handled quantity/side-change events while in the `OrderEditing` state; a failure left it in `OrderFailed` forever | Added `_resumeEditing()`, which reconstructs a fresh `OrderEditing` from `OrderFailed` so the user can correct and resubmit |
| Fixing a validation error (e.g. entering a valid quantity after "enter a positive quantity") didn't re-enable Submit | The stale `parseError` was never cleared on subsequent edits | Quantity changes now pass `clearError: true` |

## Open items

From `phase-progress.md`'s Phase 6 checklist, still outstanding:
- ❌ A full manual end-to-end scenario pass (restart persistence, duplicate-stock quotes across watchlists, reorder, stress-mode ticks, insufficient balance, invalid sells, zero-quantity holding removal)
- ❌ A walkthrough video/recording for submission

Known, deliberately-deferred tech debt (flagged by code review, not acted on — see the review's own reasoning for why):
- Four presentation files (`_QuoteRow` in Market, `WatchlistQuoteRow`, `HoldingRow`, `_OrderTile` in Activity) implement near-identical row layouts (avatar + title/subtitle + trailing value). Worth extracting into one shared row widget eventually, but the four call sites have different data shapes and actions, so it's a real refactor, not a quick win.
- `README.md` still describes the pre-redesign feature set (no mention of dark mode / sparklines / search / Activity tab / feed toggle) — worth a pass before external sharing.

## Where things live

```
lib/
  app/                      # DI composition root, MaterialApp shell, ThemeCubit, TradingStateCubit
  core/
    money/                  # Money (paise-based, no doubles)
    theme/                  # AppTheme (light/dark), MarketColors theme extension
    widgets/                # Sparkline (CustomPainter)
    domain/, data/          # Shared TradingState entity + persistence repository
  features/
    market/                 # Mock feed, MarketCubit, Market tab (search/sort/sparklines)
    watchlists/             # WatchlistCubit, watchlist CRUD/reorder UI
    orders/                 # OrderBloc, ticket + confirmation + order-history pages
    holdings/                # HoldingsCubit, holdings UI
    home/                   # Bottom-nav shell (HomePage)
test/                       # Unit tests (money, feed, use cases, persistence) + widget tests (3 full-flow suites)
docs/
  phase-progress.md         # Phase-by-phase completion checklist
  trading-app-phase-plan.md # The original phase-by-phase plan this was built against
  concepts-and-architecture.md  # Deep explanation of every concept/pattern used
  handover.md               # This file
```

## Conventions worth preserving

- **Money is always `Money` (paise int), never `double`.**
- **New cubits/blocs are registered via `registerFactory` in `service_locator.dart`**, not singletons — this keeps widget tests hermetic (each test file's `configureDependencies()` call gets fresh state).
- **Semantic gain/loss colors go through `context.marketColors`**, never a hardcoded hex — this is what makes dark mode correct everywhere automatically.
- **Anything the market feed's tick rate affects (sparklines, live sort) should read from `MarketState`, not poll `MarketRepository` directly** — the cubit is the single source of truth the UI subscribes to.
