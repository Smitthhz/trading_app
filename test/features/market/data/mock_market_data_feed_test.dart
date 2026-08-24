import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/money/money.dart';
import 'package:trading_app/features/market/data/datasources/mock_market_data_feed.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/domain/entities/stock_symbol.dart';

void main() {
  test('emits one tick for every supported stock in a batch', () async {
    final initialQuotes = [
      for (final symbol in StockSymbol.values)
        Quote(
          symbol: symbol,
          openingPrice: const Money.fromPaise(10000),
          lastTradedPrice: const Money.fromPaise(10000),
        ),
    ];
    final feed = MockMarketDataFeed(
      initialQuotes: initialQuotes,
      random: Random(7),
    );
    final ticks = feed.ticks.take(StockSymbol.values.length).toList();

    feed.emitBatch();

    expect((await ticks).map((quote) => quote.symbol), StockSymbol.values);
    await feed.dispose();
  });

  test('restarts at the configured stress tick rate', () async {
    final feed = MockMarketDataFeed(
      initialQuotes: [
        for (final symbol in StockSymbol.values)
          Quote(
            symbol: symbol,
            openingPrice: const Money.fromPaise(10000),
            lastTradedPrice: const Money.fromPaise(10000),
          ),
      ],
    );

    feed.start();
    feed.configureTickRate(MockMarketDataFeed.stressTicksPerSecondPerStock);

    expect(feed.isRunning, isTrue);
    expect(
      feed.ticksPerSecondPerStock,
      MockMarketDataFeed.stressTicksPerSecondPerStock,
    );
    await feed.dispose();
  });
}
