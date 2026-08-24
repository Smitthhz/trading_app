import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/presentation/cubit/trading_state_cubit.dart';
import '../../../../core/domain/entities/trading_state.dart';
import '../../../../core/money/money.dart';
import '../../../holdings/domain/entities/holding.dart';
import '../../../market/presentation/cubit/market_cubit.dart';

enum HoldingSortOrder {
  pnlDescending,
  pnlAscending,
  symbolAz,
  valueDescending,
}

class HoldingsState extends Equatable {
  const HoldingsState({
    required this.holdings,
    required this.sortOrder,
  });

  final List<Holding> holdings;
  final HoldingSortOrder sortOrder;

  /// Returns holdings sorted using [marketState] for P&L/value comparisons.
  List<Holding> sortedFor(MarketState marketState) {
    final list = [...holdings];
    switch (sortOrder) {
      case HoldingSortOrder.pnlDescending:
        list.sort((a, b) {
          final pnlA = _pnl(a, marketState).paise;
          final pnlB = _pnl(b, marketState).paise;
          return pnlB.compareTo(pnlA);
        });
      case HoldingSortOrder.pnlAscending:
        list.sort((a, b) {
          final pnlA = _pnl(a, marketState).paise;
          final pnlB = _pnl(b, marketState).paise;
          return pnlA.compareTo(pnlB);
        });
      case HoldingSortOrder.symbolAz:
        list.sort((a, b) => a.symbol.value.compareTo(b.symbol.value));
      case HoldingSortOrder.valueDescending:
        list.sort((a, b) {
          final valA = _currentValue(a, marketState).paise;
          final valB = _currentValue(b, marketState).paise;
          return valB.compareTo(valA);
        });
    }
    return list;
  }

  /// Aggregate summary computed from [marketState].
  ({Money totalInvested, Money currentValue, Money pnl, int pnlBasisPoints})
      summaryFor(MarketState marketState) {
    var totalInvested = Money.zero;
    var currentValue = Money.zero;
    for (final h in holdings) {
      totalInvested = totalInvested + h.investedValue;
      currentValue = currentValue + _currentValue(h, marketState);
    }
    final pnl = currentValue - totalInvested;
    final pnlBp = totalInvested.paise == 0
        ? 0
        : (pnl.paise * 10000) ~/ totalInvested.paise;
    return (
      totalInvested: totalInvested,
      currentValue: currentValue,
      pnl: pnl,
      pnlBasisPoints: pnlBp,
    );
  }

  static Money _currentValue(Holding h, MarketState m) =>
      m.quoteFor(h.symbol).lastTradedPrice.multiply(h.quantity);

  static Money _pnl(Holding h, MarketState m) =>
      _currentValue(h, m) - h.investedValue;

  HoldingsState copyWith({
    List<Holding>? holdings,
    HoldingSortOrder? sortOrder,
  }) {
    return HoldingsState(
      holdings: holdings ?? this.holdings,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object> get props => [holdings, sortOrder];
}

class HoldingsCubit extends Cubit<HoldingsState> {
  HoldingsCubit({required TradingStateCubit tradingStateCubit})
      : super(HoldingsState(
          holdings:
              tradingStateCubit.state.tradingState?.holdings ?? const [],
          sortOrder: HoldingSortOrder.pnlDescending,
        )) {
    _subscription = tradingStateCubit.stream.listen((viewState) {
      if (viewState.tradingState != null) {
        syncFrom(viewState.tradingState!);
      }
    });
  }

  late final StreamSubscription<TradingStateViewState> _subscription;

  void setSortOrder(HoldingSortOrder order) {
    emit(state.copyWith(sortOrder: order));
  }

  void syncFrom(TradingState tradingState) {
    emit(state.copyWith(holdings: tradingState.holdings));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }

  /// P&L in basis points for a single holding at a given LTP.
  static int pnlBasisPoints(Holding h, Money ltp) {
    final currentValue = ltp.multiply(h.quantity);
    final pnl = currentValue - h.investedValue;
    if (h.investedValue.paise == 0) return 0;
    return (pnl.paise * 10000) ~/ h.investedValue.paise;
  }

  /// Current value for a single holding at a given LTP.
  static Money currentValue(Holding h, Money ltp) => ltp.multiply(h.quantity);

  /// P&L money for a single holding at a given LTP.
  static Money pnl(Holding h, Money ltp) => currentValue(h, ltp) - h.investedValue;
}
