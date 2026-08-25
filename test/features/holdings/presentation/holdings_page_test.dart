import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/app/trading_app.dart';
import 'package:trading_app/app/di/service_locator.dart';
import 'package:trading_app/features/market/domain/repositories/market_repository.dart';
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
  testWidgets('shows the empty state, then reflects an executed buy order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
    await tester.pumpWidget(const TradingApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await _settle(tester);
    expect(find.text('No Holdings Yet'), findsOneWidget);

    // Buy 5 RELIANCE shares from the Market tab. The market list defaults
    // to an alphabetical sort, so search for RELIANCE to bring its row
    // into the lazily-built viewport. Lowercase avoids the search
    // field's own EditableText also matching find.text('RELIANCE').
    await tester.tap(find.byIcon(Icons.candlestick_chart_outlined));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'reliance');
    await tester.pump();

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
    await tester.enterText(quantityFieldFinder, '5');
    await tester.pump();
    await tester.tap(submitButtonFinder);
    await _settle(tester);
    expect(find.text('Order Executed!'), findsOneWidget);
    await tester.tap(find.text('Back to Home'));
    // "Back to Home" pops two routes (confirmation + ticket) at once;
    // one settle cycle isn't enough to fully resolve both transitions.
    await _settle(tester);
    await _settle(tester);
    await _settle(tester);

    // Holdings should now reflect the executed order.
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await _settle(tester);

    expect(find.text('No Holdings Yet'), findsNothing);
    expect(find.text('RELIANCE'), findsOneWidget);
    expect(find.textContaining('5 shares'), findsOneWidget);

    await serviceLocator<MarketRepository>().dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
