# 📈 Flutter Trading App

A fully simulated stock-trading app built with Flutter, featuring real-time mock price feeds, persistent watchlists, buy/sell order execution, and a live P&L portfolio — built as a technical assignment.

---

## ✨ Features

| Feature | Details |
|---|---|
| **Live Market Overview** | 10 NSE-listed stocks with tick-by-tick mock price updates, scoped green/red flash animations, sparklines, search, sorting, and a feed pause/resume control |
| **Watchlists** | Create, rename, delete multiple watchlists; drag-to-reorder; swipe-to-remove; live quotes per row |
| **Buy / Sell Orders** | Pre-filled order ticket with inline validation, LTP snapshot at submission, wallet deduction/credit |
| **Holdings & P&L** | Live portfolio with current value, weighted average cost, P&L in ₹ and %; sortable by P&L / symbol / value |
| **Activity** | Persisted order history, newest first |
| **Theme** | System, light, and dark modes with a persisted preference |
| **Persistence** | All state (wallet, holdings, watchlists, order history) survives app restarts via `shared_preferences` |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK — stable channel, compatible with Dart `^3.11.5`
- Dart SDK `^3.11.5` (bundled with Flutter)
- A connected device or simulator/emulator

### Run

```bash
flutter pub get
flutter run
```

> First launch seeds an empty **"My Watchlist"** and a starting wallet balance of **₹1,00,000**.

### Tests

```bash
flutter test
```

---

## 🏗️ Architecture

Clean Architecture with a **feature-first** folder layout:

```
lib/
├── app/                    # App shell, routing, DI composition root
├── core/
│   ├── domain/             # Shared entities & repository contracts
│   ├── data/               # SharedPreferences persistence layer
│   ├── money/              # Paise-based money type (no doubles)
│   └── theme/              # App-wide theme
└── features/
    ├── market/             # Mock feed, MarketBloc, live price grid
    ├── watchlists/         # WatchlistCubit, CRUD, reorder, picker
    ├── orders/             # OrderBloc (idle→validating→submitting→done), ticket UI
    └── holdings/           # HoldingsCubit, P&L calculations, sort
```

### Key design decisions

- **State management:** `flutter_bloc` — Cubit by default; full Bloc only where event sequencing matters (order execution, market stream).
- **Granular rebuilds:** `BlocSelector` scoped per stock symbol — a RELIANCE tick never rebuilds the TCS row.
- **Money precision:** All monetary values stored and computed in **integer paise** (`₹123.45 → 12345`). `double` is never used for financial math.
- **Order integrity:** Price is snapshotted exactly once at submission. Validation, mutation, history record, and confirmation screen all use the same snapshot.
- **Dependency injection:** `get_it` as a single composition root; presentation never touches data sources directly.

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc ^9.1.1` | State management (Cubit + Bloc) |
| `shared_preferences ^2.5.5` | Local persistence |
| `equatable ^2.1.0` | Value equality for domain entities |
| `get_it ^9.2.1` | Service locator / DI |

---

## 🧪 Test Coverage

Unit tests cover:

- Paise money arithmetic and formatting
- Weighted average cost calculation on buy
- Buy/sell validation rules (insufficient balance, invalid quantity, over-sell)
- Holdings P&L computation
- Persistence serialization/deserialization round-trips
- Mock market feed tick determinism
- Widget flows for market, watchlists, order submission, and holdings

---

## 🛠️ Debug Utilities

The mock feed exposes named rates in `MockMarketDataFeed`. The default produces one update per second for each stock; switch the default to the stress rate to produce 50+ stock ticks per second overall:

```dart
// lib/features/market/data/datasources/mock_market_data_feed.dart
static const standardTicksPerSecondPerStock = 1.0;
static const stressTicksPerSecondPerStock = 5.0;
```

## 🎥 Submission walkthrough

Use the short [walkthrough script](docs/walkthrough-script.md) to record the required end-to-end demo. It covers the live market feed, watchlist management, buy/sell validation and execution, holdings P&L, sorting, persistence, and activity history in about three minutes.

---

## 📋 Stock Universe

| Symbol | Company |
|---|---|
| RELIANCE | Reliance Industries |
| TCS | Tata Consultancy Services |
| INFY | Infosys |
| HDFCBANK | HDFC Bank |
| ICICIBANK | ICICI Bank |
| SBIN | State Bank of India |
| ITC | ITC Limited |
| LT | Larsen & Toubro |
| BHARTIARTL | Bharti Airtel |
| AXISBANK | Axis Bank |

---

## 📁 Project Docs

- [`docs/trading-app-phase-plan.md`](docs/trading-app-phase-plan.md) — Full phase-wise build plan (Phases 0–6), architecture decisions, risks, and milestones.

---

## 📄 License

This project was built as a technical assignment. All market data is simulated and for demonstration purposes only.
