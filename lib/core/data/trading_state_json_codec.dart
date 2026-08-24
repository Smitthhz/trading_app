import 'dart:convert';

import '../domain/entities/trading_state.dart';
import '../../features/holdings/domain/entities/holding.dart';
import '../../features/market/domain/entities/stock_symbol.dart';
import '../../features/orders/domain/entities/order.dart';
import '../../features/orders/domain/entities/order_side.dart';
import '../../features/orders/domain/entities/wallet.dart';
import '../../features/watchlists/domain/entities/watchlist.dart';
import '../money/money.dart';

class TradingStateJsonCodec {
  const TradingStateJsonCodec._();

  static String encode(TradingState state) => jsonEncode({
    'walletPaise': state.wallet.availableBalance.paise,
    'watchlists': state.watchlists
        .map(
          (watchlist) => {
            'id': watchlist.id,
            'name': watchlist.name,
            'symbols': watchlist.symbols.map((symbol) => symbol.value).toList(),
          },
        )
        .toList(),
    'holdings': state.holdings
        .map(
          (holding) => {
            'symbol': holding.symbol.value,
            'quantity': holding.quantity,
            'averageCostPaise': holding.averageCost.paise,
          },
        )
        .toList(),
    'orders': state.orders
        .map(
          (order) => {
            'id': order.id,
            'symbol': order.symbol.value,
            'side': order.side.name,
            'quantity': order.quantity,
            'executionPricePaise': order.executionPrice.paise,
            'executedAt': order.executedAt.toIso8601String(),
          },
        )
        .toList(),
  });

  static TradingState decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final watchlists = (json['watchlists'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (entry) => Watchlist(
            id: entry['id'] as String,
            name: entry['name'] as String,
            symbols: (entry['symbols'] as List<dynamic>)
                .cast<String>()
                .map(StockSymbol.fromValue)
                .toList(),
          ),
        )
        .toList();
    final holdings = (json['holdings'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (entry) => Holding(
            symbol: StockSymbol.fromValue(entry['symbol'] as String),
            quantity: entry['quantity'] as int,
            averageCost: Money.fromPaise(entry['averageCostPaise'] as int),
          ),
        )
        .toList();
    final orders = (json['orders'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (entry) => Order(
            id: entry['id'] as String,
            symbol: StockSymbol.fromValue(entry['symbol'] as String),
            side: OrderSide.fromValue(entry['side'] as String),
            quantity: entry['quantity'] as int,
            executionPrice: Money.fromPaise(
              entry['executionPricePaise'] as int,
            ),
            executedAt: DateTime.parse(entry['executedAt'] as String),
          ),
        )
        .toList();

    return TradingState(
      wallet: Wallet(
        availableBalance: Money.fromPaise(json['walletPaise'] as int),
      ),
      watchlists: watchlists,
      holdings: holdings,
      orders: orders,
    );
  }
}
