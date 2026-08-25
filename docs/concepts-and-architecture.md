# Trading App — Concepts & Architecture Explained

This document explains **what** this app does, **how** it's built, and **why** it's built that way — including the alternatives we considered and didn't pick, and why. It's written so you can read it once and then explain any part of this codebase to someone else — a reviewer, a teammate, or an interviewer.

> New to some of this? [`simple-explanation.md`](./simple-explanation.md) covers the exact same ground in plain, jargon-light language with everyday analogies — read that first if any of the terms below feel unfamiliar.

---

## 1. What this app is

A simulated stock trading app: 10 fixed stocks tick with randomized live prices, you can watchlist them, buy/sell with a simulated wallet, track your holdings' live P&L, and see your order history. No real backend — everything is generated locally and persisted on-device.

---

## 2. The architecture: Clean Architecture, feature-first

The codebase is split by **feature**, and each feature is split into three layers:

```
lib/features/<feature>/
  domain/         ← pure business logic, no Flutter imports
    entities/       (e.g. Quote, Holding, Order)
    repositories/    (abstract interfaces, e.g. MarketRepository)
    usecases/        (e.g. ExecuteOrder)
  data/           ← implements the domain's repository interfaces
    datasources/     (e.g. MockMarketDataFeed — the thing that actually generates data)
    repositories/    (e.g. MarketRepositoryImpl — wraps the datasource)
  presentation/   ← Flutter UI + state management
    cubit/ or bloc/  (state holders)
    pages/           (screens)
    widgets/         (reusable UI pieces)
```

**Why split it this way?** The `domain` layer never imports Flutter — it's just Dart classes and business rules. That means:
- You could swap `MockMarketDataFeed` for a real WebSocket client without touching a single widget.
- Business logic (e.g. "can I sell more shares than I hold?") lives in one testable place (`ExecuteOrder`), not scattered across widgets.
- `presentation` depends on `domain` (via abstract interfaces), never directly on `data`. This is the **Dependency Inversion Principle** — high-level code (UI) doesn't depend on low-level details (how data is fetched), both depend on an abstraction (`MarketRepository`).

**Dependency injection**: `lib/app/di/service_locator.dart` is the single place where concrete implementations get wired to their abstract interfaces, using the [`get_it`](https://pub.dev/packages/get_it) package as a service locator. Example:

```dart
serviceLocator.registerLazySingleton<MarketRepository>(
  () => MarketRepositoryImpl(feed: serviceLocator()),
);
```

Anywhere in the app, `serviceLocator<MarketRepository>()` gets you the same configured instance, without any file needing to know *which* concrete class implements the interface.

### Why Clean Architecture and not a simpler flat structure?

For a 10-screen assignment-scale app, `lib/screens/`, `lib/widgets/`, `lib/models/` (organized by *type*, not *feature*) would genuinely be less code and faster to write on day one. We didn't do that, on purpose:
- **Organizing by feature, not by type, means everything related to one change lives together.** Adding "order history" touched one `orders/` folder, not four scattered folders (`screens/`, `blocs/`, `models/`, `repositories/`) you have to jump between.
- **The domain layer's "no Flutter imports" rule is what makes `ExecuteOrder` a one-line unit test** (`execute_order_test.dart`) instead of something you can only exercise by pumping a whole widget tree. If business logic and UI are mixed in one widget's `onPressed`, you can only test it by simulating taps.
- **The trade-off is real**, and worth naming honestly: more files, more ceremony (an interface *and* an implementation for every repository), and more to read before you understand one feature end-to-end. This pays off once the app is big enough that "where do I even put this?" becomes a real question — for a much smaller app (a single-screen utility, a prototype), this structure would be overkill and a flat `lib/` would be the right call.

### Why `get_it` and not Provider-only / Riverpod for dependency injection?

`flutter_bloc` already pulls in `provider` as a dependency (that's what `BlocProvider`/`RepositoryProvider` are built on), so we could have skipped `get_it` entirely and constructed everything as nested `MultiProvider`/`MultiRepositoryProvider` trees. We used `get_it` for the **non-widget** dependencies instead (repositories, use cases, the mock feed) because:
- Those objects need to exist and be *the same instance* regardless of what's currently on screen (the mock feed must keep ticking whether or not the Market tab is mounted) — a service locator models "app-lifetime singletons" more directly than a widget tree, where a provider's lifetime is tied to where it's placed in that tree.
- It keeps `configureDependencies()` as one linear, readable list of "here's everything the app needs and how to build it," instead of a deeply nested pyramid of `Provider` widgets each depending on the one above it.

We still use `Provider`'s `BlocProvider`/`RepositoryProvider` for the *widget-scoped* things (giving a screen access to a Cubit) — the two tools aren't competing, they're solving different halves of the same problem (long-lived services vs. widget-tree-scoped state).

**Why `registerFactory` (fresh instance every time) for Cubits, but `registerLazySingleton` (one shared instance) for repositories?** These are genuinely different lifetimes, and `get_it` makes you choose explicitly per registration:
- Repositories/the mock feed (`registerLazySingleton`) need to be **one instance for the app's entire life** — there's only one live price feed, one wallet balance source of truth. Two instances would mean two independent, disagreeing "truths."
- Cubits (`registerFactory`) are cheap to build and are meant to be **scoped to whatever widget subtree currently needs them** — `MarketCubit` gets created once when `TradingApp` builds its `BlocProvider`, but the factory pattern means each widget test's `configureDependencies()` call gets a *fresh*, independent set of cubits rather than silently reusing state left over from a previous test. This was a deliberate, easy-to-miss detail: getting it wrong (making cubits singletons too) wouldn't break the running app, but it would make widget tests leak state into each other.

---

## 3. State management: `flutter_bloc` (Cubit vs Bloc)

This app uses the [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) package, which implements the BLoC (Business Logic Component) pattern: **UI never mutates state directly — it calls a method on a Cubit/Bloc, which emits a new state, and the UI rebuilds in response.**

### Cubit vs Bloc — when we used which

- **Cubit** (`WatchlistCubit`, `HoldingsCubit`, `MarketCubit`, `ThemeCubit`, `TradingStateCubit`, `HomeNavigationCubit`): simple — you call a method, it emits a new state directly. Used for straightforward state changes (toggle theme, add a symbol, load data).
- **Bloc** (`OrderBloc`): event-driven — you dispatch typed *events* (`OrderQuantityChanged`, `OrderSubmitRequested`), and the bloc's registered handlers process them into new *states*. Used here because order submission has a real **sequence** to protect: `editing → submitting → succeeded/failed`. Modeling it as explicit events makes that sequencing impossible to skip accidentally (you can't jump straight to "submitting" without going through "editing" first).

### The three ways to listen to a Cubit/Bloc in the UI

| Widget | Purpose |
|---|---|
| `BlocBuilder<C, S>` | Rebuild UI when state changes. |
| `BlocListener<C, S>` | Run a **side effect** (navigate, show a SnackBar) when state changes — doesn't rebuild UI itself. |
| `BlocConsumer<C, S>` | Both of the above combined. |

All three accept optional `buildWhen`/`listenWhen` callbacks — `(previousState, currentState) => bool` — to control *which* state changes actually trigger a rebuild/side-effect. This app uses this heavily for performance: e.g. `MarketOverviewPage`'s per-row widget only rebuilds when *its own symbol's* quote changed, not on every tick of the other 9 stocks:

```dart
BlocConsumer<MarketCubit, MarketState>(
  buildWhen: (prev, curr) => prev.quoteFor(symbol) != curr.quoteFor(symbol),
  listenWhen: (prev, curr) => prev.quoteFor(symbol) != curr.quoteFor(symbol),
  listener: (context, state) => _triggerFlash(),   // side effect: flash animation
  builder: (context, state) => ...,                 // rebuild this row only
)
```

⚠️ **A real gotcha we hit**: `BlocBuilder` only refreshes its *internally cached* state inside the `buildWhen`-gated listener (verified by reading `flutter_bloc`'s actual source). If you gate `buildWhen` to `false` for a stretch, and then something *else* (like a parent widget's `setState`) forces a rebuild, `BlocBuilder.builder` runs again with **stale cached state**, not the latest. We initially wrote a "skip rebuilding while sorted alphabetically" optimization on the Market page that had exactly this bug — removed it, since with only 10 items the "optimization" wasn't worth the risk.

### Why `flutter_bloc` and not Provider / Riverpod / GetX / plain `setState`?

This is a real, common Flutter decision, so it's worth being explicit about the trade-offs rather than treating BLoC as the only option:

- **vs. plain `setState` everywhere**: works fine for a single screen's local state (which is exactly why we *did* use plain `setState` for the Market page's search/sort — see §10). It falls apart once state needs to be shared across screens (the wallet balance is used by the ticket, the confirmation screen, and holdings) — `setState` has no answer for "notify a widget three screens away that something changed" without lifting state awkwardly high up the tree.
- **vs. Riverpod**: Riverpod is arguably the more modern choice today — compile-time-safe provider references, no `BuildContext` needed to read state, first-class support for auto-disposing/caching. We didn't use it mainly because the codebase was already committed to `flutter_bloc` conventions (Cubit/Bloc, `BlocProvider`) before this session started, and there's no functional gap `flutter_bloc` has here that would justify a mid-project migration. If starting fresh today, Riverpod would be a legitimate alternative to seriously weigh.
- **vs. GetX**: GetX bundles state management, DI, *and* routing into one package with a lot of "magic" (global reactive variables, minimal boilerplate). We avoided it because that convenience comes at the cost of explicitness — with `flutter_bloc`, every state transition is a named, typed class you can grep for and unit-test in isolation; GetX's reactive `.obs` variables make that harder to trace, especially as an app grows.
- **vs. Provider alone (no Cubit/Bloc)**: `ChangeNotifier` + `Provider` is simpler to learn, but every state mutation is an imperative `notifyListeners()` call with no built-in concept of "what changed" — you lose the clean `buildWhen`/`listenWhen` granularity (§3) that this app leans on heavily for the 5×/sec price-tick performance case.

None of these are "wrong" choices in general — `flutter_bloc` won here mainly for **explicitness and testability at the cost of some boilerplate** (an event, a state, and a bloc class for even a simple flow), which matched what this project already had.

---

## 4. The reactive data pipeline (how live prices flow to the screen)

```
MockMarketDataFeed (Timer.periodic)
  → emits a Quote on a Stream, once per tick, per symbol
  → MarketRepositoryImpl (just forwards the stream)
    → MarketCubit subscribes to the stream in its constructor
      → on each tick: emit(state.withQuote(quote))
        → BlocConsumer in each row rebuilds *only if that row's symbol ticked*
```

- `MockMarketDataFeed` (`lib/features/market/data/datasources/mock_market_data_feed.dart`) uses a `Timer.periodic` to emit a random bounded price move for **all 10 stocks** on each tick, onto a `StreamController<Quote>`.
- Tick rate is configurable: `standardTicksPerSecondPerStock = 1.0`, `stressTicksPerSecondPerStock = 5.0` — this is the "stress mode" toggle in the AppBar, used to prove the UI doesn't jank under load.
- `MarketCubit`'s state (`MarketState`) holds a `Map<StockSymbol, Quote>` — the latest known price for every symbol — plus a `Map<StockSymbol, List<int>>` price-history buffer (capped at 30 points) that feeds the sparkline charts.
- The **feed keeps running independently of any screen** — it's started once in `MarketCubit`'s constructor (registered once via DI), not tied to a widget's lifecycle. Navigate away and back, prices are still current.

### Why this fan-out pattern instead of one big rebuild?

With 10 stocks ticking up to 5×/sec each (50 updates/sec in stress mode), rebuilding the *entire* list on every tick would be wasteful and would visibly jank. Instead:
- The **cubit's state** always has the full picture (a `Map`), updated on every tick.
- Each **row widget** only cares about its own symbol, and uses `buildWhen` to ignore ticks for other symbols.

This is the single most important performance pattern in the app, and it's used identically for the Market list, Watchlist rows, and Holdings rows.

---

## 5. Money: why everything is stored in paise (integers)

`lib/core/money/money.dart` wraps a single `int paise` field — never a `double`.

```dart
class Money {
  const Money.fromPaise(this.paise);
  const Money.fromRupees(int rupees) : paise = rupees * 100;
}
```

**Why not `double`?** Floating point can't represent `0.1` exactly in binary — repeated addition/subtraction of money as `double` accumulates rounding errors (this is a classic, real-world bug class). Representing money as an integer count of the smallest unit (paise, like cents) makes all arithmetic exact. This is the same reason financial systems typically store cents/paise as integers, not decimals.

**Why not the `decimal` package** (a real alternative for Dart money code)? A `Decimal` type gives you exact base-10 arithmetic without hand-rolling the paise conversion — a legitimate choice, and arguably more readable at call sites (`Decimal.parse('123.45')` vs `Money.fromPaise(12345)`). We didn't reach for it because integers-as-smallest-unit needs zero external dependency, has no parsing/serialization surface to get wrong, and the domain here (quantities × price, all integers or paise-integers) never needs true decimal *division* — every operation we do (`+`, `-`, `× quantity`) stays exact in plain integer math. `decimal` would earn its place if the app needed things like splitting a value into N equal parts or genuine decimal rounding rules.

---

## 6. The order execution flow — "snapshot once" pattern

`OrderBloc` (`lib/features/orders/presentation/bloc/order_bloc.dart`) models the buy/sell flow as a state machine:

```
OrderEditing → (submit) → OrderSubmitting → OrderSucceeded
                                          ↘ OrderFailed
```

The critical correctness rule: **the execution price is captured exactly once**, at the moment of submission (`_marketRepository.currentQuotes.firstWhere(...)`), and that *one* snapshot is used for validation, the wallet deduction, the holding update, and the confirmation screen. If instead the code re-read the live price at each of those steps, a fast-ticking stock could execute at a different price than what the user saw when they hit "Submit" — a real trading-app correctness bug class.

`ExecuteOrder` (a use case in `domain/usecases/`) is a pure function: given a `TradingState`, a side, a symbol, a quantity, and the snapshotted quote, it returns either a new `TradingState` + `Order`, or a typed error (`invalidQuantity`, `insufficientBalance`, `insufficientQuantity`). It has zero Flutter dependencies, so it's trivially unit-testable (`test/features/orders/domain/usecases/execute_order_test.dart`).

### A bug we found and fixed here: recovering from a failed order

Originally, `OrderBloc` only handled `OrderQuantityChanged`/`OrderSideToggled` events while `state is OrderEditing`. Once an order failed (e.g. insufficient balance), the state became `OrderFailed` — and since neither handler would touch anything but `OrderEditing`, **the ticket became permanently stuck**: no further edits, no way to retry, only "go back and reopen." The fix — `_resumeEditing()` — reconstructs a fresh `OrderEditing` from `OrderFailed` whenever the user starts editing again, so the whole point of showing "insufficient balance, try a smaller quantity" isn't followed by a UI that won't let them.

---

## 7. Persistence: `shared_preferences` + JSON

`SharedPreferencesTradingStateRepository` loads/saves the *entire* `TradingState` (wallet, watchlists, holdings, order history) as one JSON blob under a single key, via `TradingStateJsonCodec`. On load, if the saved JSON is missing or corrupt, it falls back to `AppSeed.initial()` (empty watchlist + ₹1,00,000 starting balance) rather than crashing.

**Why one blob instead of separate keys per field?** Simplicity, and it guarantees atomicity — a `save()` either writes the whole consistent state or doesn't, there's no window where wallet and holdings are out of sync because one write succeeded and another didn't.

**Why `shared_preferences` and not a real local database** (`sqlite`/`drift`, `hive`, `isar`)? A database earns its place when you need to *query* a subset of data efficiently (e.g. "give me orders from the last 7 days" without deserializing everything), when the dataset can grow large, or when you need relational integrity across many linked tables. This app's entire persisted state is small (one wallet, a handful of watchlists/holdings, a bounded order list) and is always read/written as one unit — there's no partial-query use case anywhere in the app. Reaching for a database here would mean writing migration/schema code, learning that package's API, and gaining nothing over "serialize the whole state to JSON, save it under one key." If order history were expected to grow to thousands of entries with filtering/pagination requirements, that calculus would flip.

### A bug we found and fixed here: the async-load race

`TradingStateCubit` starts in a `.loading()` state (`tradingState == null`) and only becomes `.ready(...)` after `load()` — an async `SharedPreferences` read — completes. `OrderBloc`'s constructor used to force-unwrap that value with `!`. In practice this microtask-scale race is nearly impossible to hit by hand, but it's real (we reproduced it both in a widget test and live in the browser by tapping a stock immediately after the page loaded). The fix has two parts:
1. `OrderTicketPage.push()` checks `tradingState == null` first and shows a "not ready, try again" SnackBar instead of navigating.
2. `OrderBloc`'s constructor now *requires* a non-null `TradingState` as a parameter, instead of reading a nullable field and unwrapping it — moving the safety check from a runtime `!` to something the compiler enforces.

**Why change the constructor instead of just keeping the `!` but checking for null first at the call site (which we'd already done in step 1)?** Because step 1 alone only protects the *one current* call site. A `!` inside `OrderBloc` is still a landmine for whoever adds a second way to open a ticket later, or writes a unit test that constructs `OrderBloc` directly — they'd hit the exact same crash with no compiler warning. Requiring the value as a constructor parameter makes the invariant impossible to violate from *any* call site, present or future, without extra work like a fallback object — this is generally preferable to a runtime null-check whenever you can express the same guarantee in the type system instead.

---

## 8. Theming: Material 3, `ColorScheme.fromSeed`, and dark mode

`AppTheme` (`lib/core/theme/app_theme.dart`) builds two `ThemeData` objects — light and dark — both derived from **one seed color** via `ColorScheme.fromSeed(seedColor: _seed, brightness: ...)`. This is Material 3's way of generating a whole harmonious palette (primary, secondary, tertiary, surface tones, etc.) from a single brand color, rather than hand-picking a dozen colors that have to be kept visually consistent by hand.

**Why seed-based instead of a hand-authored `ColorScheme(...)` with every color picked explicitly?** Hand-picking gives pixel-perfect control, but you're then responsible for choosing (and keeping in sync across a light *and* dark variant) 20+ individual colors — primary, on-primary, primary container, secondary, error, every surface tone — such that they all satisfy Material's contrast/accessibility guidelines. `ColorScheme.fromSeed` derives all of that algorithmically from one color, so light/dark are guaranteed to be internally consistent and accessible by construction. The trade-off: less bespoke control over the exact shade of every single slot — acceptable here since the app doesn't have unusual branding requirements beyond "look like a trustworthy fintech app."

### `ThemeExtension` for custom semantic colors

Gain/loss colors (green for profit, red for loss) aren't part of Material's built-in `ColorScheme` — they're specific to this app. Rather than hardcoding hex colors in a dozen widgets (which is exactly what the original code did, and which breaks in dark mode — a light-green badge background that looks great on white looks washed-out on near-black), we defined a `ThemeExtension`:

```dart
class MarketColors extends ThemeExtension<MarketColors> {
  final Color gain, loss, gainContainer, lossContainer;
  static const light = MarketColors(...);  // tuned for light backgrounds
  static const dark = MarketColors(...);   // tuned for dark backgrounds
}
```

registered via `ThemeData(extensions: [marketColors])`, and read anywhere via `Theme.of(context).extension<MarketColors>()` (wrapped in a `context.marketColors` extension getter for convenience). This is the standard Flutter pattern for "theme values that aren't part of `ColorScheme`" — one source of truth, correct in both themes automatically.

### How the dark-mode toggle actually works

`ThemeCubit` holds a `ThemeMode` (`system` / `light` / `dark`), persisted to `SharedPreferences` under its own key. `MaterialApp` is given all three theming inputs:

```dart
MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: themeMode)
```

Flutter resolves which `ThemeData` to actually use based on `themeMode` (and the OS setting, if `themeMode == system`). The AppBar's toggle button just calls `ThemeCubit.cycle()`, which flips `system → light → dark → system` and re-persists.

---

## 9. Sparklines: hand-rolled `CustomPainter`, not a chart library

Rather than pull in a charting dependency for a tiny inline trend line, `Sparkline` (`lib/core/widgets/sparkline.dart`) is a `CustomPainter` — Flutter's low-level 2D drawing API (`Canvas`, `Paint`, `Path`).

**Why not a package like `fl_chart` or `syncfusion_flutter_charts`?** Those packages are the right call when you need axes, legends, tooltips, zoom/pan, or multiple chart types — real charting features. A sparkline is deliberately the opposite: no axes, no labels, no interaction, just a tiny trend line repeated ~30 times on screen (one per row). Pulling in a full charting library for that is a heavy dependency (larger app size, another API surface to learn, another package to keep updated) for something `CustomPainter` does in about 40 lines with zero dependencies. If the app later needed a full-screen, interactive price chart (tap for exact values, pinch to zoom, multiple timeframes), that would be the point to reach for a real charting package instead of extending the hand-rolled painter.

The core idea of any `CustomPainter`:
```dart
class MyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) { /* draw with canvas.drawX(...) */ }
  @override
  bool shouldRepaint(covariant MyPainter old) => /* did the drawable data change? */;
}
```
`Sparkline` takes a `List<int>` of recent prices, normalizes them to fit the widget's height (`min`/`max` → 0..1 → pixel Y), and draws a connected line (`Path.lineTo`) plus a soft gradient fill beneath it. The data comes from `MarketState.historyBySymbol` — a capped rolling buffer appended to on every tick (see §4) — so the sparkline is just "the last 30 points of the same data the price text already shows," no separate data-fetching involved.

---

## 10. Search & sort (Market tab)

`MarketOverviewPage` is a `StatefulWidget` holding two pieces of **purely local UI state** — a search query `String` and a `_MarketSort` enum (`name` / `priceDesc` / `changeDesc`). On every rebuild, `_visibleSymbols(marketState)` filters `StockSymbol.values` by substring match (symbol code or company name) and sorts the result.

This is intentionally **not** stored in a Cubit — it's transient, page-scoped UI state with no reason to survive navigating away, so plain `setState` is the simplest correct tool (don't reach for BLoC when `setState` is enough).

One nuance: **sorting by Price/%Change needs live data**, but sorting by Name doesn't (alphabetical order never changes). So the list only re-subscribes to *every* market tick when a live sort is active — see the `buildWhen` gotcha in §3 for why that optimization had to be written carefully.

---

## 11. New features added and why

| Feature | What it is | Where |
|---|---|---|
| **Dark mode** | System/light/dark toggle, persisted | `ThemeCubit`, AppBar icon |
| **Sparklines** | Mini trend charts on every row | `Sparkline` widget, `MarketState.historyBySymbol` |
| **Market search & sort** | Filter/sort the 10-stock list | `MarketOverviewPage` local state |
| **Order History ("Activity" tab)** | Read-only list of every executed order | `OrderHistoryPage`, reads `TradingState.orders` |
| **Feed stop/resume** | Freeze/unfreeze live prices | `MarketRepository.stop()`/`isRunning`, `MarketCubit.toggleFeed()` |

The **feed toggle** is a good example of *where a new capability belongs in a layered app*: the underlying `MockMarketDataFeed` already had `stop()`/`isRunning`, but the abstract `MarketRepository` interface didn't expose them — so the fix wasn't "add a stop method," it was "add it to the interface, implement it in the concrete repository, mirror it into the cubit's state (matching the existing `isStressMode` pattern), then wire a button to it." Every layer had to agree on the new capability before the UI could use it — that's the cost (and the value) of the layered architecture.

---

## 12. Testing: widget tests and the gotchas we learned

Widget tests in Flutter run inside a **simulated ("fake async") clock** — `tester.pump(duration)` advances virtual time and flushes pending work, rather than actually waiting in real time. This makes tests fast and deterministic, but it has sharp edges we hit directly while writing these tests:

1. **`pumpAndSettle()` can hang forever** if something in the widget tree keeps scheduling new frames indefinitely — which `MarketCubit`'s real `Timer.periodic` does the moment the app starts. We had to replace `pumpAndSettle()` with bounded, explicit `pump()` calls everywhere.
2. **Real async races are testable, not just theoretical** — the `TradingStateCubit` load race from §7 reproduced reliably in tests once we tapped a row immediately after `pumpWidget`, which is exactly how we found it needed guarding.
3. **List reconciliation needs `Key`s when order is dynamic** — Flutter matches widgets between rebuilds by *type and position* unless given an explicit `Key`. Once the Market list gained a live sort (search/reorder can change which symbol sits at index 3 between frames), the per-row `StatefulWidget` (which owns flash-animation state) needed `key: ValueKey(symbol.value)`, or Flutter could hand one stock's animation state to a different stock that happened to land in the same list position.

All of this is why the project has real widget tests (not just unit tests) for the watchlist, order-ticket, and holdings flows — they don't just check "does this text appear," they exercise real navigation, real async loading, and real bloc wiring, which is exactly what caught the bugs above.

---

## 13. Architecture decision log — why this, not that

A quick-reference table of every notable "we picked X over Y" decision in this codebase, for scanning without hunting through prose above. Where a decision is explained in more depth earlier, that section is linked.

| Decision | What we chose | Alternatives considered | Why we didn't pick them |
|---|---|---|---|
| Folder structure | Clean Architecture, feature-first (§2) | Flat `lib/screens,widgets,models/`; layer-first (`lib/blocs/`, `lib/pages/`) | More files/ceremony, but keeps everything about one feature together and makes business logic (`ExecuteOrder`) testable without a widget tree. Would be overkill for a much smaller app. |
| State management | `flutter_bloc` (Cubit + Bloc) (§3) | Riverpod, GetX, Provider+`ChangeNotifier` alone, plain `setState` | Riverpod is a legitimate modern alternative, mainly not used because the project already used BLoC conventions. GetX trades explicitness for magic. Provider alone loses the `buildWhen`/`listenWhen` granularity the price-tick performance case leans on. Plain `setState` doesn't scale to cross-screen state (wallet balance used on 3+ screens). |
| Cubit vs Bloc per feature | Cubit for simple state, Bloc only for `OrderBloc` (§3) | Bloc everywhere, for consistency | Order submission has a real state *sequence* (editing→submitting→succeeded/failed) worth modeling as explicit events; everything else is a direct "call a method, get a new state," where Bloc's event layer would be pure ceremony. |
| Dependency injection | `get_it` service locator for repositories/datasources | Nested `Provider`/`MultiProvider` trees for everything | Long-lived, app-wide singletons (the price feed) don't naturally fit a widget-tree-scoped tool. `Provider` is still used, but only for widget-scoped Cubits. |
| Cubit registration lifetime | `registerFactory` (fresh instance per resolve) | `registerLazySingleton` (one shared instance) | Widget tests need independent, non-leaking state per test run; a shared singleton cubit would let one test's state bleed into the next. |
| Money representation | Integer paise (`Money.fromPaise`) (§5) | `double`; the `decimal` package | `double` accumulates rounding error on repeated arithmetic — a real bug class for money. `decimal` is a fair alternative but adds a dependency for exact-decimal math this app never actually needs (no division into fractional parts). |
| Persistence | `shared_preferences` + one JSON blob (§7) | A local database (`sqlite`/`drift`, `hive`, `isar`); one storage key per field | The whole app state is small and always read/written as one unit — no partial-query use case exists to justify a database's schema/migration overhead. One blob (vs. per-field keys) guarantees atomic, consistent saves. |
| Null-safety for `OrderBloc`'s trading state | Required constructor parameter (compiler-enforced) (§7) | A runtime `null` check with a `!` unwrap, guarded only at the call site | A call-site-only guard protects just that one call site; a future second caller (or a test constructing the bloc directly) would hit the same crash. Moving the guarantee into the type system protects every caller, present and future. |
| Theming | `ColorScheme.fromSeed` (Material 3) (§8) | Hand-authored `ColorScheme` with every color picked explicitly | Hand-picking ~20+ colors that must stay consistent (and accessible) across light *and* dark is a lot of manual upkeep; seed-based generation guarantees internal consistency by construction, at the cost of pixel-level control the app doesn't need. |
| Custom semantic colors (gain/loss) | A `ThemeExtension` (§8) | Hardcoded hex colors scattered per-widget; `if (isDark) ... else ...` checks inline | Hardcoded colors (the original state of this codebase) don't adapt to dark mode and duplicate the same hex values ~15 times. A `ThemeExtension` is Flutter's sanctioned single-source-of-truth mechanism for exactly this. |
| Sparkline charts | Hand-rolled `CustomPainter` (§9) | A charting package (`fl_chart`, Syncfusion) | A sparkline needs no axes/legend/interaction — the features a charting library exists for. A full package would be a heavy dependency for ~40 lines of canvas drawing. Would flip if the app needed a real interactive chart screen. |
| Market search/sort state | Local `StatefulWidget` + `setState` (§10) | A dedicated `MarketFilterCubit` | The search query and sort mode are transient, page-scoped UI state with no reason to survive navigation or be shared — reaching for a Cubit here would be state-management ceremony with no benefit. |
| Recovering from a failed order | Reconstruct `OrderEditing` from `OrderFailed` in the bloc (§6) | Force the user to fully back out and reopen the ticket after any failure | The latter is what the app originally did (a real bug, not a design choice) — it directly undermines the point of showing a specific "why it failed" message if the user then can't act on it. |

---

## 14. Quick glossary

- **Cubit / Bloc** — state containers from `flutter_bloc`; Cubit = direct method calls, Bloc = typed events.
- **`buildWhen` / `listenWhen`** — filters that control whether a state change triggers a rebuild / side effect.
- **Repository pattern** — an abstract interface (`MarketRepository`) that hides *how* data is fetched from the code that *uses* the data.
- **Use case** — a single pure business operation (`ExecuteOrder`), independent of UI or storage.
- **`ColorScheme.fromSeed`** — Material 3 API that generates a full, harmonious color palette from one seed color.
- **`ThemeExtension`** — the sanctioned way to add custom (non-Material) theme values that still respond correctly to light/dark mode.
- **`CustomPainter`** — Flutter's low-level canvas drawing API, used here for the sparkline charts.
- **Snapshot-once pattern** — capturing a value (like a live price) exactly once at the moment it matters, instead of re-reading it at each step of a multi-step operation.
- **Fake async (widget testing)** — Flutter test's simulated clock; `pump()` advances virtual time deterministically instead of waiting in real time.
