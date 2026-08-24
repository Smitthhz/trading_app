import 'package:equatable/equatable.dart';

import '../../../market/domain/entities/stock_symbol.dart';

class Watchlist extends Equatable {
  Watchlist({
    required this.id,
    required this.name,
    required List<StockSymbol> symbols,
  }) : symbols = List.unmodifiable(symbols);

  final String id;
  final String name;
  final List<StockSymbol> symbols;

  Watchlist copyWith({String? name, List<StockSymbol>? symbols}) {
    return Watchlist(
      id: id,
      name: name ?? this.name,
      symbols: symbols ?? this.symbols,
    );
  }

  @override
  List<Object> get props => [id, name, symbols];
}
