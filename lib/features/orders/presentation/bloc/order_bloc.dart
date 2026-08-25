import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/presentation/cubit/trading_state_cubit.dart';
import '../../../../core/domain/entities/trading_state.dart';
import '../../../../core/money/money.dart';
import '../../../holdings/domain/entities/holding.dart';
import '../../../market/domain/entities/stock_symbol.dart';
import '../../../market/domain/repositories/market_repository.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_side.dart';
import '../../domain/usecases/execute_order.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc({
    required StockSymbol symbol,
    required OrderSide initialSide,
    required TradingState initialTradingState,
    required TradingStateCubit tradingStateCubit,
    required MarketRepository marketRepository,
    required ExecuteOrder executeOrder,
  }) : _tradingStateCubit = tradingStateCubit,
       _marketRepository = marketRepository,
       _executeOrder = executeOrder,
       super(
         OrderEditing(
           symbol: symbol,
           side: initialSide,
           rawQuantity: '',
           tradingState: initialTradingState,
         ),
       ) {
    on<OrderSideToggled>(_onSideToggled);
    on<OrderQuantityChanged>(_onQuantityChanged);
    on<OrderSubmitRequested>(_onSubmitRequested);
  }

  final TradingStateCubit _tradingStateCubit;
  final MarketRepository _marketRepository;
  final ExecuteOrder _executeOrder;

  void _onSideToggled(OrderSideToggled event, Emitter<OrderState> emit) {
    final editing = _resumeEditing();
    if (editing == null) return;
    final nextSide = editing.side == OrderSide.buy
        ? OrderSide.sell
        : OrderSide.buy;
    emit(editing.copyWith(side: nextSide));
  }

  void _onQuantityChanged(
    OrderQuantityChanged event,
    Emitter<OrderState> emit,
  ) {
    final editing = _resumeEditing();
    if (editing == null) return;
    emit(editing.copyWith(rawQuantity: event.raw, clearError: true));
  }

  /// Returns the current [OrderEditing] state to mutate, reconstructing one
  /// from [OrderFailed] if needed — otherwise a failed order permanently
  /// locks the ticket, since neither side-toggle nor quantity edits are
  /// handled outside [OrderEditing].
  OrderEditing? _resumeEditing() {
    final current = state;
    if (current is OrderEditing) return current;
    if (current is OrderFailed) {
      final tradingState = _tradingStateCubit.state.tradingState;
      if (tradingState == null) return null;
      return OrderEditing(
        symbol: current.symbol,
        side: current.side,
        rawQuantity: '',
        tradingState: tradingState,
      );
    }
    return null;
  }

  Future<void> _onSubmitRequested(
    OrderSubmitRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (state is! OrderEditing) return;
    final s = state as OrderEditing;

    final qty = int.tryParse(s.rawQuantity.trim());
    if (qty == null || qty <= 0) {
      emit(s.copyWith(parseError: 'Enter a valid positive quantity'));
      return;
    }

    emit(OrderSubmitting(symbol: s.symbol, side: s.side, quantity: qty));

    // Snapshot the current quote exactly once
    final quote = _marketRepository.currentQuotes.firstWhere(
      (q) => q.symbol == s.symbol,
    );

    final currentState = _tradingStateCubit.state.tradingState;
    if (currentState == null) {
      emit(
        OrderFailed(
          symbol: s.symbol,
          side: s.side,
          message: 'App state not ready. Please try again.',
        ),
      );
      return;
    }

    final result = _executeOrder(
      state: currentState,
      side: s.side,
      symbol: s.symbol,
      quantity: qty,
      executionQuote: quote,
    );

    if (result.isSuccess) {
      await _tradingStateCubit.persist(result.state!);
      emit(OrderSucceeded(order: result.order!, newState: result.state!));
    } else {
      final message = switch (result.error!) {
        OrderExecutionError.invalidQuantity =>
          'Quantity must be a positive integer.',
        OrderExecutionError.insufficientBalance =>
          'Insufficient wallet balance for this order.',
        OrderExecutionError.insufficientQuantity =>
          'You don\'t hold enough shares to sell.',
      };
      emit(OrderFailed(symbol: s.symbol, side: s.side, message: message));
    }
  }
}
