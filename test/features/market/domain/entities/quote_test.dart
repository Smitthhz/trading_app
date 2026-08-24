import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/money/money.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/domain/entities/stock_symbol.dart';

void main() {
  test('calculates quote change without floating-point math', () {
    const quote = Quote(
      symbol: StockSymbol.reliance,
      openingPrice: Money.fromPaise(10000),
      lastTradedPrice: Money.fromPaise(10125),
    );

    expect(quote.change, const Money.fromPaise(125));
    expect(quote.changeBasisPoints, 125);
  });
}
