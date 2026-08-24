import 'package:equatable/equatable.dart';

import '../../../market/domain/entities/stock_symbol.dart';
import '../../../../core/money/money.dart';

class Holding extends Equatable {
  const Holding({
    required this.symbol,
    required this.quantity,
    required this.averageCost,
  });

  final StockSymbol symbol;
  final int quantity;
  final Money averageCost;

  Money get investedValue => averageCost.multiply(quantity);

  @override
  List<Object> get props => [symbol, quantity, averageCost];
}
