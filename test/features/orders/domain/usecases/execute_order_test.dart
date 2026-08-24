import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/domain/entities/trading_state.dart';
import 'package:trading_app/core/money/money.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/domain/entities/stock_symbol.dart';
import 'package:trading_app/features/orders/domain/entities/order_side.dart';
import 'package:trading_app/features/orders/domain/entities/wallet.dart';
import 'package:trading_app/features/orders/domain/usecases/execute_order.dart';

void main() {
  const quote = Quote(
    symbol: StockSymbol.reliance,
    openingPrice: Money.fromPaise(1000),
    lastTradedPrice: Money.fromPaise(1000),
  );
  final state = TradingState(
    wallet: const Wallet(availableBalance: Money.fromPaise(10000)),
    watchlists: const [],
    holdings: const [],
    orders: const [],
  );
  final executeOrder = ExecuteOrder(
    clock: () => DateTime.utc(2026, 8, 22),
    idGenerator: () => 'order-1',
  );

  test(
    'buy updates balance, holding quantity, average cost, and order history',
    () {
      final result = executeOrder(
        state: state,
        side: OrderSide.buy,
        symbol: StockSymbol.reliance,
        quantity: 3,
        executionQuote: quote,
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.state!.wallet.availableBalance,
        const Money.fromPaise(7000),
      );
      expect(result.state!.holdings.single.quantity, 3);
      expect(
        result.state!.holdings.single.averageCost,
        const Money.fromPaise(1000),
      );
      expect(result.state!.orders.single.value, const Money.fromPaise(3000));
    },
  );

  test('rejects a sell that exceeds the held quantity', () {
    final result = executeOrder(
      state: state,
      side: OrderSide.sell,
      symbol: StockSymbol.reliance,
      quantity: 1,
      executionQuote: quote,
    );

    expect(result.isSuccess, isFalse);
    expect(result.error, OrderExecutionError.insufficientQuantity);
  });
}
