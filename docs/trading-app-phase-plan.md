# Flutter Trading App — Phase-wise Plan

## Goal

Deliver a Flutter trading-app assignment that runs with `flutter pub get && flutter run`, provides persistent watchlists, a single mock live-price feed, simulated buy/sell orders, and a live holdings portfolio.

## Recommended technical choices

- **State:** `flutter_bloc`, with **Cubit as the default** for feature state and straightforward UI actions. Use a full Bloc only where event sequencing is useful (such as order execution or a high-rate market stream). Use `BlocBuilder` and `BlocSelector` narrowly so a tick rebuilds only affected cells.
- **Architecture:** Clean Architecture with a feature-first `data` / `domain` / `presentation` split. Presentation depends on domain abstractions, data implements repositories, and domain owns entities, repository contracts, and use cases.
- **Persistence:** `shared_preferences` with JSON-encoded app data for watchlists, wallet, holdings, and order history.
- **Money:** integer paise (for example, `₹123.45 = 12345`) for price, balance, value, and P&L calculations. Never use `double` for financial calculations.
- **Quantity:** positive whole-number shares, as implied by the assignment’s fractional-quantity validation requirement.
- **Mock feed:** one long-lived service with a configurable timer/tick rate. It owns the current quote for each of the ten symbols and exposes symbol-scoped reactive updates.

## Phase 0 — Bootstrap and foundation

**Objective:** Establish a runnable, maintainable project skeleton before building screens.

1. Create the Flutter project on the stable channel and verify `flutter pub get` and `flutter run`.
2. Add dependencies for state management and local persistence.
3. Create the core folder structure:

   ```text
   lib/
     app/                         # app shell, routes, dependency wiring
     core/                        # errors, money formatting, IDs, shared widgets
     features/
       market/
         data/                    # feed/repository implementations, DTOs
         domain/                  # entities, contracts, use cases
         presentation/            # MarketCubit/Bloc, pages, widgets
       watchlists/
         data/
         domain/
         presentation/            # WatchlistCubit, pages, widgets
       orders/
         data/
         domain/
         presentation/            # OrderBloc/Cubit, ticket/confirmation UI
       holdings/
         data/
         domain/
         presentation/            # HoldingsCubit, pages, widgets
   ```

4. Define the fixed stock universe: RELIANCE, TCS, INFY, HDFCBANK, ICICIBANK, SBIN, ITC, LT, BHARTIARTL, AXISBANK, with sensible initial prices.
5. Define immutable domain entities: `Quote`, `Watchlist`, `Holding`, `Order`, and `Wallet`, plus repository contracts.
6. Register repository implementations, use cases, and Cubits/Blocs in one dependency-injection composition root.
7. Add a small seeded/default app state for first launch (for example, an empty “My Watchlist” and a ₹1,00,000 starting balance).

**Exit criteria:** App launches, navigation shell is visible, and formatting/model unit tests pass.

### State-management ownership

- `MarketBloc`: receives the mock-feed stream and emits the latest quote map; quote widgets consume individual symbols with `BlocSelector`.
- `WatchlistCubit`: loads, creates, renames, deletes, reorders, and persists watchlists.
- `OrderBloc`: owns the submit lifecycle (`idle → validating → submitting → success/failure`) so the execution snapshot and persistence mutation are sequenced safely.
- `HoldingsCubit`: owns persisted holdings, sorting preference, and structural updates after an executed order.
- `WalletCubit`: exposes the persisted balance and updates after an executed order.

Feature Cubits/Blocs may coordinate through use cases and repository streams; presentation components must not call data sources directly.

## Phase 1 — Data, persistence, and realtime architecture

**Objective:** Build shared sources of truth that every feature uses.

1. Implement a persistence repository that loads state during app startup and saves updates atomically after mutations.
2. Handle corrupt or missing saved JSON gracefully by restoring safe defaults.
3. Implement `MockMarketDataFeed`:
   - retains the latest quote for every stock;
   - emits randomized, bounded price movements at a configurable rate;
   - calculates change and change percentage relative to each stock’s session/open price;
   - stays alive independently of the currently visible screen.
4. Expose per-symbol quote streams/selectors through the market repository. Use `BlocSelector` (or dedicated quote Cubits) so changing RELIANCE does not rebuild TCS rows.
5. Implement domain operations for buy and sell using the quote snapshot at submit time.

**Exit criteria:** The market feed produces deterministic-testable ticks, state restores across restart, and all monetary calculations use paise.

## Phase 2 — Live market overview

**Objective:** Show smooth real-time market data for all ten stocks.

1. Build the market overview list/grid with symbol, LTP, change, and change percentage.
2. Add short green/red update flashes, scoped to the changed quote cell.
3. Add a debug-only tick-rate control or named constant, including a stress setting of at least 5 ticks/sec/stock.
4. Profile rendering and ensure list rows subscribe only to their own symbol’s quote.
5. Verify quotes remain current after navigation away and back.

**Exit criteria:** All ten symbols update continuously without noticeable jank at the stress rate.

## Phase 3 — Watchlists

**Objective:** Implement fully persistent, multi-watchlist management.

1. Create the watchlist screen with tabs or a selector for multiple watchlists.
2. Implement create, rename, and delete flows with sensible confirmations and validation.
3. Build an add-stock picker containing the ten available stocks; prevent duplicates within the same watchlist and communicate why an item cannot be added.
4. Implement drag-to-reorder and swipe/action removal.
5. Render each row from its symbol-scoped live quote, keyed by stable IDs/symbols so a reorder cannot associate a row with stale quote data.
6. Show an explicit empty state and route a row tap into the pre-filled order ticket.
7. Persist each mutation immediately.

**Exit criteria:** Restart restores every watchlist and ordering; duplicate symbols across two lists display the identical current quote.

## Phase 4 — Buy/Sell ticket and ledger rules

**Objective:** Make simulated orders correct, responsive, and explainable.

1. Build a ticket that accepts a preselected symbol, side toggle, and quantity input.
2. Use `BlocSelector` to subscribe the displayed LTP and projected value to the selected symbol’s live quote.
3. Validate inline:
   - symbol selected;
   - quantity is a positive integer;
   - buy cost does not exceed wallet balance;
   - sell quantity does not exceed the holding quantity.
4. On submission, take one current quote snapshot, calculate order value from that snapshot, then execute a single state transaction.
5. Buy rule: deduct balance; create/update holding; recompute weighted average cost.
6. Sell rule: credit balance; reduce/remove holding; record the executed order.
7. Persist wallet, holdings, and order history, then show an execution-confirmation screen with the exact executed price/value.

**Exit criteria:** Invalid orders cannot mutate state; successful orders remain correct after restart.

## Phase 5 — Holdings and live P&L

**Objective:** Deliver a portfolio that stays correct as quotes move.

1. Build an empty state and holdings list with symbol, quantity, average cost, LTP, current value, P&L in ₹, and P&L percentage.
2. Build a summary using the same calculation layer: total invested, current value, and total P&L in ₹ and percentage.
3. Add sorting by P&L, symbol, and current value (P&L descending by default).
4. Re-evaluate the sorted order when live price changes cross ranking boundaries, while keeping row-level quote updates granular.
5. Open the pre-filled ticket on row tap.
6. Verify that selling the final share removes the holding and updates the summary immediately.

**Exit criteria:** Summary equals the row totals at every quote state; all ten holdings remain smooth under stress ticks.

## Phase 6 — Quality, test matrix, and submission

**Objective:** Validate assignment scenarios and package a polished submission.

1. Add unit tests for money formatting/arithmetic, weighted average cost, buy/sell validation, holdings P&L, sorting, and persistence serialization.
2. Add widget tests for watchlist empty/populated states, ticket validation/errors, and holdings aggregate display.
3. Manually test the required end-to-end scenarios, including restart persistence, duplicate-stock quotes, watchlist reordering, stress ticks, insufficient balance, invalid sells, and zero-quantity holding removal.
4. Run `dart format`, `flutter analyze`, and `flutter test`; fix warnings before submission.
5. Create a concise `README.md` covering prerequisites, run commands, architecture, test commands, and the debug tick-rate setting.
6. Record a short walkthrough covering all four features and their edge cases.
7. Use small, purposeful commits (foundation, feed, watchlists, order ticket, holdings, tests/docs) and publish the public GitHub repository.

**Exit criteria:** Clean analysis/tests, verified run instructions, public repository, and walkthrough video ready to submit.

## Suggested build order and milestones

| Milestone | Deliverable |
| --- | --- |
| M1 | Project shell, models, paise utilities, persistence, mock feed |
| M2 | Smooth live market overview with stress-rate verification |
| M3 | Persistent multi-watchlist CRUD, picker, reorder, and ticket deep-link |
| M4 | Correct buy/sell execution, wallet, order history, confirmation |
| M5 | Live holdings, sortable P&L, aggregate summary |
| M6 | Tests, README, walkthrough, final smoke test |

## Risks to address early

- **Stale/rebound quote UI:** Key lists by stable entity IDs and subscribe by symbol; do not store quote state in a reordered row widget.
- **Over-rebuilding under ticks:** Keep watchlist/holding structural Cubit state separate from symbol-level market state; use `BlocSelector` for quote-dependent widgets.
- **Incorrect order price:** Snapshot the LTP once at submission and use that exact value for validation, mutation, history, and confirmation.
- **Precision defects:** Keep all rupee values in paise and format only at the UI boundary.
- **Inconsistent portfolio totals:** Centralize holding valuation and P&L calculations rather than duplicating formulas across widgets.
