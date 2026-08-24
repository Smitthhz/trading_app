import '../../core/domain/entities/trading_state.dart';
import '../../core/money/money.dart';
import '../../features/market/domain/entities/quote.dart';
import '../../features/market/domain/entities/stock_symbol.dart';
import '../../features/orders/domain/entities/wallet.dart';
import '../../features/watchlists/domain/entities/watchlist.dart';

class AppSeed {
  AppSeed._({required this.marketQuotes, required this.tradingState});

  factory AppSeed.initial() {
    const pricesInPaise = {
      StockSymbol.reliance: 284500,
      StockSymbol.tcs: 412000,
      StockSymbol.infy: 179850,
      StockSymbol.hdfcBank: 168700,
      StockSymbol.iciciBank: 136250,
      StockSymbol.sbin: 81540,
      StockSymbol.itc: 42765,
      StockSymbol.lt: 361000,
      StockSymbol.bhartiAirtel: 172450,
      StockSymbol.axisBank: 119875,
    };

    final quotes = pricesInPaise.entries
        .map(
          (entry) => Quote(
            symbol: entry.key,
            lastTradedPrice: Money.fromPaise(entry.value),
            openingPrice: Money.fromPaise(entry.value),
          ),
        )
        .toList(growable: false);

    const wallet = Wallet(availableBalance: Money.fromRupees(100000));
    final watchlists = [
      Watchlist(id: 'default', name: 'My Watchlist', symbols: const []),
    ];

    return AppSeed._(
      marketQuotes: List.unmodifiable(quotes),
      tradingState: TradingState(
        wallet: wallet,
        watchlists: watchlists,
        holdings: const [],
        orders: const [],
      ),
    );
  }

  final List<Quote> marketQuotes;
  final TradingState tradingState;
}
