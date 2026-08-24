import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'stock_symbol.dart';

class Quote extends Equatable {
  const Quote({
    required this.symbol,
    required this.lastTradedPrice,
    required this.openingPrice,
  });

  final StockSymbol symbol;
  final Money lastTradedPrice;
  final Money openingPrice;

  Money get change => lastTradedPrice - openingPrice;

  /// Percentage change expressed in basis points (1% = 100 basis points).
  int get changeBasisPoints {
    if (openingPrice.isZero) {
      return 0;
    }
    return (change.paise * 10000) ~/ openingPrice.paise;
  }

  Quote copyWith({Money? lastTradedPrice}) {
    return Quote(
      symbol: symbol,
      lastTradedPrice: lastTradedPrice ?? this.lastTradedPrice,
      openingPrice: openingPrice,
    );
  }

  @override
  List<Object> get props => [symbol, lastTradedPrice, openingPrice];
}
