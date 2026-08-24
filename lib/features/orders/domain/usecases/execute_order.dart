import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/trading_state.dart';
import '../../../../core/money/money.dart';
import '../../../holdings/domain/entities/holding.dart';
import '../../../market/domain/entities/quote.dart';
import '../../../market/domain/entities/stock_symbol.dart';
import '../entities/order.dart';
import '../entities/order_side.dart';
import '../entities/wallet.dart';

class ExecuteOrder {
  ExecuteOrder({DateTime Function()? clock, String Function()? idGenerator})
    : _clock = clock ?? DateTime.now,
      _idGenerator = idGenerator ?? _defaultId;

  final DateTime Function() _clock;
  final String Function() _idGenerator;

  OrderExecutionResult call({
    required TradingState state,
    required OrderSide side,
    required StockSymbol symbol,
    required int quantity,
    required Quote executionQuote,
  }) {
    if (quantity <= 0) {
      return const OrderExecutionResult.failure(
        OrderExecutionError.invalidQuantity,
      );
    }

    final value = executionQuote.lastTradedPrice.multiply(quantity);
    final existingHolding = _holdingFor(state.holdings, symbol);

    if (side == OrderSide.buy &&
        state.wallet.availableBalance.compareTo(value) < 0) {
      return const OrderExecutionResult.failure(
        OrderExecutionError.insufficientBalance,
      );
    }
    if (side == OrderSide.sell &&
        (existingHolding == null || existingHolding.quantity < quantity)) {
      return const OrderExecutionResult.failure(
        OrderExecutionError.insufficientQuantity,
      );
    }

    final order = Order(
      id: _idGenerator(),
      symbol: symbol,
      side: side,
      quantity: quantity,
      executionPrice: executionQuote.lastTradedPrice,
      executedAt: _clock(),
    );
    final nextState = side == OrderSide.buy
        ? _applyBuy(state, order, existingHolding)
        : _applySell(state, order, existingHolding!);

    return OrderExecutionResult.success(nextState, order);
  }

  TradingState _applyBuy(
    TradingState state,
    Order order,
    Holding? existingHolding,
  ) {
    final totalQuantity = (existingHolding?.quantity ?? 0) + order.quantity;
    final totalCost =
        (existingHolding?.investedValue ?? Money.zero) + order.value;
    final nextHolding = Holding(
      symbol: order.symbol,
      quantity: totalQuantity,
      averageCost: Money.fromPaise(totalCost.paise ~/ totalQuantity),
    );

    return state.copyWith(
      wallet: Wallet(
        availableBalance: state.wallet.availableBalance - order.value,
      ),
      holdings: _replaceHolding(state.holdings, nextHolding),
      orders: [...state.orders, order],
    );
  }

  TradingState _applySell(
    TradingState state,
    Order order,
    Holding existingHolding,
  ) {
    final remainingQuantity = existingHolding.quantity - order.quantity;
    final nextHoldings = remainingQuantity == 0
        ? state.holdings
              .where((holding) => holding.symbol != order.symbol)
              .toList()
        : _replaceHolding(
            state.holdings,
            Holding(
              symbol: existingHolding.symbol,
              quantity: remainingQuantity,
              averageCost: existingHolding.averageCost,
            ),
          );

    return state.copyWith(
      wallet: Wallet(
        availableBalance: state.wallet.availableBalance + order.value,
      ),
      holdings: nextHoldings,
      orders: [...state.orders, order],
    );
  }

  Holding? _holdingFor(List<Holding> holdings, StockSymbol symbol) {
    for (final holding in holdings) {
      if (holding.symbol == symbol) {
        return holding;
      }
    }
    return null;
  }

  List<Holding> _replaceHolding(List<Holding> holdings, Holding replacement) {
    return [
      for (final holding in holdings)
        if (holding.symbol == replacement.symbol) replacement else holding,
      if (!holdings.any((holding) => holding.symbol == replacement.symbol))
        replacement,
    ];
  }

  static String _defaultId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}

enum OrderExecutionError {
  invalidQuantity,
  insufficientBalance,
  insufficientQuantity,
}

class OrderExecutionResult extends Equatable {
  const OrderExecutionResult._({this.state, this.order, this.error});

  const OrderExecutionResult.success(TradingState state, Order order)
    : this._(state: state, order: order);

  const OrderExecutionResult.failure(OrderExecutionError error)
    : this._(error: error);

  final TradingState? state;
  final Order? order;
  final OrderExecutionError? error;

  bool get isSuccess => state != null;

  @override
  List<Object?> get props => [state, order, error];
}
