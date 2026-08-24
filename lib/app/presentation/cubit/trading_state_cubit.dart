import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/entities/trading_state.dart';
import '../../../core/domain/repositories/trading_state_repository.dart';

class TradingStateCubit extends Cubit<TradingStateViewState> {
  TradingStateCubit({required TradingStateRepository repository})
    : _repository = repository,
      super(const TradingStateViewState.loading());

  final TradingStateRepository _repository;

  Future<void> load() async {
    final state = await _repository.load();
    emit(TradingStateViewState.ready(state));
  }

  Future<void> persist(TradingState state) async {
    await _repository.save(state);
    emit(TradingStateViewState.ready(state));
  }
}

class TradingStateViewState extends Equatable {
  const TradingStateViewState.loading() : tradingState = null;

  const TradingStateViewState.ready(this.tradingState);

  final TradingState? tradingState;

  bool get isLoading => tradingState == null;

  @override
  List<Object?> get props => [tradingState];
}
