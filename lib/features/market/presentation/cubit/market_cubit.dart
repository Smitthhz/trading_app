import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quote.dart';
import '../../domain/entities/stock_symbol.dart';
import '../../domain/repositories/market_repository.dart';
import '../../../market/data/datasources/mock_market_data_feed.dart';

class MarketCubit extends Cubit<MarketState> {
  MarketCubit({required MarketRepository repository})
    : _repository = repository,
      super(
        MarketState.fromQuotes(
          repository.currentQuotes,
          isStressMode: false,
          isFeedRunning: true,
        ),
      ) {
    _subscription = _repository.quoteTicks.listen(_onQuoteTick);
    _repository.start();
  }

  final MarketRepository _repository;
  late final StreamSubscription<Quote> _subscription;

  void _onQuoteTick(Quote quote) => emit(state.withQuote(quote));

  void toggleStressMode() {
    final next = !state.isStressMode;
    _repository.configureTickRate(
      next
          ? MockMarketDataFeed.stressTicksPerSecondPerStock
          : MockMarketDataFeed.standardTicksPerSecondPerStock,
    );
    emit(state.copyWith(isStressMode: next));
  }

  /// Stops (or resumes) the live feed. Quotes freeze at their last value
  /// while stopped — tapping a row and trading still works off that
  /// frozen snapshot, it just won't move until resumed.
  void toggleFeed() {
    final next = !state.isFeedRunning;
    if (next) {
      _repository.start();
    } else {
      _repository.stop();
    }
    emit(state.copyWith(isFeedRunning: next));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

class MarketState extends Equatable {
  MarketState._({
    required Map<StockSymbol, Quote> quotesBySymbol,
    required Map<StockSymbol, List<int>> historyBySymbol,
    required this.isStressMode,
    required this.isFeedRunning,
  }) : quotesBySymbol = Map.unmodifiable(quotesBySymbol),
       historyBySymbol = Map.unmodifiable(historyBySymbol);

  /// How many recent ticks a sparkline shows per symbol.
  static const historyLength = 30;

  factory MarketState.fromQuotes(
    List<Quote> quotes, {
    required bool isStressMode,
    required bool isFeedRunning,
  }) {
    return MarketState._(
      quotesBySymbol: {for (final quote in quotes) quote.symbol: quote},
      historyBySymbol: {
        for (final quote in quotes) quote.symbol: [quote.lastTradedPrice.paise],
      },
      isStressMode: isStressMode,
      isFeedRunning: isFeedRunning,
    );
  }

  final Map<StockSymbol, Quote> quotesBySymbol;
  final Map<StockSymbol, List<int>> historyBySymbol;
  final bool isStressMode;
  final bool isFeedRunning;

  Quote quoteFor(StockSymbol symbol) => quotesBySymbol[symbol]!;

  List<int> historyFor(StockSymbol symbol) =>
      historyBySymbol[symbol] ?? const [];

  MarketState withQuote(Quote quote) {
    final existingHistory = historyBySymbol[quote.symbol] ?? const <int>[];
    final nextHistory = [...existingHistory, quote.lastTradedPrice.paise];
    final trimmedHistory = nextHistory.length > historyLength
        ? nextHistory.sublist(nextHistory.length - historyLength)
        : nextHistory;

    return MarketState._(
      quotesBySymbol: {...quotesBySymbol, quote.symbol: quote},
      historyBySymbol: {...historyBySymbol, quote.symbol: trimmedHistory},
      isStressMode: isStressMode,
      isFeedRunning: isFeedRunning,
    );
  }

  MarketState copyWith({bool? isStressMode, bool? isFeedRunning}) {
    return MarketState._(
      quotesBySymbol: quotesBySymbol,
      historyBySymbol: historyBySymbol,
      isStressMode: isStressMode ?? this.isStressMode,
      isFeedRunning: isFeedRunning ?? this.isFeedRunning,
    );
  }

  @override
  List<Object> get props => [
    quotesBySymbol,
    historyBySymbol,
    isStressMode,
    isFeedRunning,
  ];
}
