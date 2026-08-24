import '../entities/trading_state.dart';

abstract interface class TradingStateRepository {
  Future<TradingState> load();

  Future<void> save(TradingState state);
}
