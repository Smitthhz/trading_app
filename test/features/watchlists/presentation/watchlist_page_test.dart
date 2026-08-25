import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/app/trading_app.dart';
import 'package:trading_app/app/di/service_locator.dart';
import 'package:trading_app/features/market/domain/repositories/market_repository.dart';

/// A bounded settle: pumpAndSettle() is unsafe here because MarketCubit
/// starts a real 1-tick/sec Timer.periodic on app start, which keeps
/// scheduling frames forever and never lets pumpAndSettle converge.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets(
    'shows empty state, adds a stock from the picker, and prevents duplicates',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await configureDependencies();
      await tester.pumpWidget(const TradingApp());
      await tester.pump(const Duration(milliseconds: 50));

      // Switch to the Watchlists tab.
      await tester.tap(find.byIcon(Icons.star_border));
      await _settle(tester);

      // The seeded "My Watchlist" starts empty.
      expect(find.text('No stocks yet'), findsOneWidget);

      // Open the stock picker from the empty-state CTA.
      await tester.tap(find.text('Add Stocks'));
      await _settle(tester);
      expect(find.text('Add Stocks'), findsWidgets);

      // Select RELIANCE and TCS.
      await tester.tap(find.text('RELIANCE'));
      await _settle(tester);
      await tester.tap(find.text('TCS'));
      await _settle(tester);

      // Tap the bottom CTA to add both selected stocks.
      await tester.tap(find.text('Add 2 Stocks'));
      await _settle(tester);

      expect(find.text('No stocks yet'), findsNothing);
      expect(find.text('RELIANCE'), findsOneWidget);
      expect(find.text('TCS'), findsOneWidget);

      // Reopen the picker via the non-empty-state FAB and confirm the
      // already-added symbols are disabled with "Added" chips.
      await tester.tap(find.text('Add Stock'));
      await _settle(tester);
      expect(find.text('Added'), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.close));
      await _settle(tester);

      await serviceLocator<MarketRepository>().dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
