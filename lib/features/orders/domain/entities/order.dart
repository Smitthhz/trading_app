import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import '../../../market/domain/entities/stock_symbol.dart';
import 'order_side.dart';

class Order extends Equatable {
  const Order({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.executionPrice,
    required this.executedAt,
  });

  final String id;
  final StockSymbol symbol;
  final OrderSide side;
  final int quantity;
  final Money executionPrice;
  final DateTime executedAt;

  Money get value => executionPrice.multiply(quantity);

  @override
  List<Object> get props => [
    id,
    symbol,
    side,
    quantity,
    executionPrice,
    executedAt,
  ];
}
