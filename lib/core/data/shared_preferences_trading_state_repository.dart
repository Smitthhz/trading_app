import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/trading_state.dart';
import '../domain/repositories/trading_state_repository.dart';
import 'trading_state_json_codec.dart';

class SharedPreferencesTradingStateRepository
    implements TradingStateRepository {
  SharedPreferencesTradingStateRepository({
    required SharedPreferences preferences,
    required TradingState fallbackState,
  }) : _preferences = preferences,
       _fallbackState = fallbackState;

  static const _storageKey = 'trading_state_v1';

  final SharedPreferences _preferences;
  final TradingState _fallbackState;

  @override
  Future<TradingState> load() async {
    final source = _preferences.getString(_storageKey);
    if (source == null) {
      return _fallbackState;
    }

    try {
      return TradingStateJsonCodec.decode(source);
    } on FormatException {
      return _fallbackState;
    } on TypeError {
      return _fallbackState;
    } on StateError {
      return _fallbackState;
    }
  }

  @override
  Future<void> save(TradingState state) {
    return _preferences.setString(
      _storageKey,
      TradingStateJsonCodec.encode(state),
    );
  }
}
