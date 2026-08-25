import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/app/trading_app.dart';
import 'package:trading_app/app/di/service_locator.dart';
import 'package:trading_app/features/market/domain/repositories/market_repository.dart';
import 'package:trading_app/features/orders/presentation/pages/order_confirmation_page.dart';
import 'package:trading_app/features/orders/presentation/pages/order_ticket_page.dart';

/// A bounded settle: pumpAndSettle() is unsafe here because MarketCubit
/// starts a real 1-tick/sec Timer.periodic on app start, which keeps
/// scheduling frames forever and never lets pumpAndSettle converge.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Taps [tapTarget] repeatedly until [expectFound] appears. The very first
/// tap can race TradingStateCubit's async startup load (SharedPreferences
/// resolves slower than a single pump cycle under the test binding), in
/// which case OrderTicketPage.push() no-ops with a snackbar — so retry
/// instead of pinning an exact number of pumps to the load.
Future<void> _tapUntil(
  WidgetTester tester,
  Finder tapTarget,
  Finder expectFound,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (expectFound.evaluate().isNotEmpty) return;
    await tester.tap(tapTarget, warnIfMissed: false);
    await _settle(tester);
  }
  expect(expectFound, findsOneWidget);
}

void main() {
  testWidgets(
    'disables submit until a valid quantity is entered, then executes a buy',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await configureDependencies();
      await tester.pumpWidget(const TradingApp());
      await tester.pump();

      // The market list defaults to an alphabetical sort, so search for
      // RELIANCE to bring its row into the lazily-built viewport. Lowercase
      // avoids the search field's own EditableText also matching
      // find.text('RELIANCE') (the row label is always upper-case).
      await tester.enterText(find.byType(TextField), 'reliance');
      await tester.pump();

      // Tap the market row to open the ticket.
      final submitButtonFinder = find.widgetWithText(
        FilledButton,
        'Place Buy Order',
      );
      await _tapUntil(tester, find.text('RELIANCE').first, submitButtonFinder);

      // The Market tab's search field is still mounted beneath the pushed
      // ticket route, so scope the quantity field to avoid ambiguity.
      final quantityFieldFinder = find.descendant(
        of: find.byType(OrderTicketPage),
        matching: find.byType(TextField),
      );

      expect(tester.widget<FilledButton>(submitButtonFinder).onPressed, isNull);

      await tester.enterText(quantityFieldFinder, '3');
      await tester.pump();

      expect(
        tester.widget<FilledButton>(submitButtonFinder).onPressed,
        isNotNull,
      );

      await tester.tap(submitButtonFinder);
      await _settle(tester);

      // Execution confirmation screen. The ticket page stays mounted
      // beneath it in the Navigator stack, so scope finders to avoid
      // matching its still-present side-toggle labels.
      final confirmation = find.byType(OrderConfirmationPage);
      expect(confirmation, findsOneWidget);
      expect(find.text('Order Executed!'), findsOneWidget);
      expect(
        find.descendant(of: confirmation, matching: find.text('BUY')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: confirmation, matching: find.text('RELIANCE')),
        findsOneWidget,
      );
      expect(find.text('3 shares'), findsOneWidget);

      await tester.tap(find.text('Back to Home'));
      // "Back to Home" pops two routes (confirmation + ticket) at once;
      // one settle cycle isn't enough to fully resolve both transitions.
      await _settle(tester);
      await _settle(tester);
      await _settle(tester);

      // Back on the Market tab.
      expect(find.text('Market'), findsNWidgets(2));

      await serviceLocator<MarketRepository>().dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
