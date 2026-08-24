import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quote.dart';
import '../../domain/entities/stock_symbol.dart';
import '../../domain/repositories/market_repository.dart';

class MarketCubit extends Cubit<MarketState> {
  MarketCubit({required MarketRepository repository})
    : _repository = repository,
      super(MarketState.fromQuotes(repository.currentQuotes)) {
    _subscription = _repository.quoteTicks.listen(_onQuoteTick);
    _repository.start();
  }

  final MarketRepository _repository;
  late final StreamSubscription<Quote> _subscription;

  void _onQuoteTick(Quote quote) => emit(state.withQuote(quote));

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

class MarketState extends Equatable {
  MarketState._({required Map<StockSymbol, Quote> quotesBySymbol})
    : quotesBySymbol = Map.unmodifiable(quotesBySymbol);

  factory MarketState.fromQuotes(List<Quote> quotes) {
    return MarketState._(
      quotesBySymbol: {for (final quote in quotes) quote.symbol: quote},
    );
  }

  final Map<StockSymbol, Quote> quotesBySymbol;

  Quote quoteFor(StockSymbol symbol) => quotesBySymbol[symbol]!;

  MarketState withQuote(Quote quote) {
    return MarketState._(
      quotesBySymbol: {...quotesBySymbol, quote.symbol: quote},
    );
  }

  @override
  List<Object> get props => [quotesBySymbol];
}
