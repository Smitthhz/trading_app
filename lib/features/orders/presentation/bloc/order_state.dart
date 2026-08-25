part of 'order_bloc.dart';

sealed class OrderState extends Equatable {
  const OrderState();
}

/// User is entering data. Carries live validation state.
class OrderEditing extends OrderState {
  const OrderEditing({
    required this.symbol,
    required this.side,
    required this.rawQuantity,
    required this.tradingState,
    this.parseError,
  });

  final StockSymbol symbol;
  final OrderSide side;
  final String rawQuantity;
  final TradingState tradingState;
  final String? parseError;

  int? get parsedQuantity {
    final qty = int.tryParse(rawQuantity.trim());
    return (qty != null && qty > 0) ? qty : null;
  }

  bool get canSubmit => parsedQuantity != null && parseError == null;

  /// The holding for this symbol, if one exists.
  Holding? get existingHolding {
    for (final h in tradingState.holdings) {
      if (h.symbol == symbol) return h;
    }
    return null;
  }

  /// Projected order value = quantity * LTP (computed by UI with live quote).
  /// Available balance / quantity are derived from tradingState in the UI.
  Money get walletBalance => tradingState.wallet.availableBalance;

  int get heldQuantity => existingHolding?.quantity ?? 0;

  OrderEditing copyWith({
    OrderSide? side,
    String? rawQuantity,
    String? parseError,
    bool clearError = false,
  }) {
    return OrderEditing(
      symbol: symbol,
      side: side ?? this.side,
      rawQuantity: rawQuantity ?? this.rawQuantity,
      tradingState: tradingState,
      parseError: clearError ? null : (parseError ?? this.parseError),
    );
  }

  @override
  List<Object?> get props => [
    symbol,
    side,
    rawQuantity,
    tradingState,
    parseError,
  ];
}

/// Waiting for the use-case to complete.
class OrderSubmitting extends OrderState {
  const OrderSubmitting({
    required this.symbol,
    required this.side,
    required this.quantity,
  });

  final StockSymbol symbol;
  final OrderSide side;
  final int quantity;

  @override
  List<Object> get props => [symbol, side, quantity];
}

/// Order executed successfully.
class OrderSucceeded extends OrderState {
  const OrderSucceeded({required this.order, required this.newState});

  final Order order;
  final TradingState newState;

  @override
  List<Object> get props => [order, newState];
}

/// Execution failed (validation or error).
class OrderFailed extends OrderState {
  const OrderFailed({
    required this.symbol,
    required this.side,
    required this.message,
  });

  final StockSymbol symbol;
  final OrderSide side;
  final String message;

  @override
  List<Object> get props => [symbol, side, message];
}
