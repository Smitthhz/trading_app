import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/money/money.dart';

void main() {
  test('keeps decimal arithmetic exact in paise', () {
    const price = Money.fromPaise(1999);

    expect(price.multiply(3).paise, 5997);
    expect(
      (price.multiply(3) - const Money.fromPaise(1999)).formatted,
      '₹39.98',
    );
  });
}
