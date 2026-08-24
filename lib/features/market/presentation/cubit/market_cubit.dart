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
        super(MarketState.fromQuotes(
          repository.currentQuotes,
          isStressMode: false,
        )) {
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

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

class MarketState extends Equatable {
  MarketState._({
    required Map<StockSymbol, Quote> quotesBySymbol,
    required this.isStressMode,
  }) : quotesBySymbol = Map.unmodifiable(quotesBySymbol);

  factory MarketState.fromQuotes(
    List<Quote> quotes, {
    required bool isStressMode,
  }) {
    return MarketState._(
      quotesBySymbol: {for (final quote in quotes) quote.symbol: quote},
      isStressMode: isStressMode,
    );
  }

  final Map<StockSymbol, Quote> quotesBySymbol;
  final bool isStressMode;

  Quote quoteFor(StockSymbol symbol) => quotesBySymbol[symbol]!;

  MarketState withQuote(Quote quote) {
    return MarketState._(
      quotesBySymbol: {...quotesBySymbol, quote.symbol: quote},
      isStressMode: isStressMode,
    );
  }

  MarketState copyWith({bool? isStressMode}) {
    return MarketState._(
      quotesBySymbol: quotesBySymbol,
      isStressMode: isStressMode ?? this.isStressMode,
    );
  }

  @override
  List<Object> get props => [quotesBySymbol, isStressMode];
}
