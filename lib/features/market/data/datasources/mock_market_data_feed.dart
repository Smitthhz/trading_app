import 'dart:async';
import 'dart:math';

import '../../../../core/money/money.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/stock_symbol.dart';

class MockMarketDataFeed {
  MockMarketDataFeed({
    required List<Quote> initialQuotes,
    this.ticksPerSecondPerStock = standardTicksPerSecondPerStock,
    Random? random,
  }) : assert(ticksPerSecondPerStock > 0),
       _random = random ?? Random(),
       _quotes = {for (final quote in initialQuotes) quote.symbol: quote};

  static const standardTicksPerSecondPerStock = 1.0;
  static const stressTicksPerSecondPerStock = 5.0;

  final Random _random;
  final Map<StockSymbol, Quote> _quotes;
  final StreamController<Quote> _controller = StreamController.broadcast();
  double ticksPerSecondPerStock;
  Timer? _timer;

  List<Quote> get currentQuotes => List.unmodifiable(_quotes.values);

  Stream<Quote> get ticks => _controller.stream;

  bool get isRunning => _timer?.isActive ?? false;

  void start() {
    if (isRunning) {
      return;
    }
    _timer = Timer.periodic(_tickInterval, (_) => emitBatch());
  }

  void configureTickRate(double value) {
    if (value <= 0) {
      throw ArgumentError.value(value, 'value', 'Must be greater than zero.');
    }
    final shouldRestart = isRunning;
    stop();
    ticksPerSecondPerStock = value;
    if (shouldRestart) {
      start();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Emits one updated tick for each supported stock.
  void emitBatch() {
    for (final symbol in StockSymbol.values) {
      final current = _quotes[symbol]!;
      final next = current.copyWith(lastTradedPrice: _nextPrice(current));
      _quotes[symbol] = next;
      _controller.add(next);
    }
  }

  Future<void> dispose() async {
    stop();
    await _controller.close();
  }

  Duration get _tickInterval {
    return Duration(
      microseconds: (Duration.microsecondsPerSecond / ticksPerSecondPerStock)
          .round(),
    );
  }

  Money _nextPrice(Quote quote) {
    final maximumMove = max(1, quote.lastTradedPrice.paise ~/ 5000);
    final move = _random.nextInt(maximumMove * 2 + 1) - maximumMove;
    final nextPaise = max(1, quote.lastTradedPrice.paise + move);
    return Money.fromPaise(nextPaise);
  }
}
