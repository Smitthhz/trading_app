import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_app/app/seed/app_seed.dart';
import 'package:trading_app/core/data/shared_preferences_trading_state_repository.dart';

void main() {
  test('restores the fallback state when saved JSON is corrupt', () async {
    SharedPreferences.setMockInitialValues({
      'trading_state_v1': 'not valid json',
    });
    final seed = AppSeed.initial();
    final repository = SharedPreferencesTradingStateRepository(
      preferences: await SharedPreferences.getInstance(),
      fallbackState: seed.tradingState,
    );

    expect(await repository.load(), seed.tradingState);
  });

  test('round-trips a saved trading state', () async {
    SharedPreferences.setMockInitialValues({});
    final seed = AppSeed.initial();
    final repository = SharedPreferencesTradingStateRepository(
      preferences: await SharedPreferences.getInstance(),
      fallbackState: seed.tradingState,
    );

    await repository.save(seed.tradingState);

    expect(await repository.load(), seed.tradingState);
  });
}
