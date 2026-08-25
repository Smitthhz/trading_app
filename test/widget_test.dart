import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/app/trading_app.dart';
import 'package:trading_app/app/di/service_locator.dart';
import 'package:trading_app/features/market/domain/repositories/market_repository.dart';

void main() {
  testWidgets('shows the market overview on launch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
    await tester.pumpWidget(const TradingApp());

    expect(find.text('Market'), findsNWidgets(2));
    expect(find.text('Watchlists'), findsOneWidget);
    expect(find.text('Holdings'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);

    // The market list defaults to an alphabetical sort, so RELIANCE isn't
    // in the first lazily-built viewport — search for it to bring it up.
    // Lowercase avoids the search field's own EditableText also matching
    // find.text('RELIANCE') (the row label is always upper-case).
    await tester.enterText(find.byType(TextField), 'reliance');
    await tester.pump();
    expect(find.text('RELIANCE'), findsOneWidget);

    await serviceLocator<MarketRepository>().dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
