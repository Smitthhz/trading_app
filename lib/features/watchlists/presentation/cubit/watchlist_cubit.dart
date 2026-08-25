import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/presentation/cubit/trading_state_cubit.dart';
import '../../../../core/domain/entities/trading_state.dart';
import '../../../market/domain/entities/stock_symbol.dart';
import '../../domain/entities/watchlist.dart';

part 'watchlist_state.dart';

class WatchlistCubit extends Cubit<WatchlistState> {
  WatchlistCubit({required TradingStateCubit tradingStateCubit})
    : _tradingStateCubit = tradingStateCubit,
      super(
        WatchlistState(
          watchlists: tradingStateCubit.state.tradingState?.watchlists ?? [],
          selectedIndex: 0,
        ),
      ) {
    // TradingStateCubit.load() is async — sync once data arrives
    _subscription = tradingStateCubit.stream.listen((viewState) {
      if (viewState.tradingState != null) {
        syncFrom(viewState.tradingState!);
      }
    });
  }

  final TradingStateCubit _tradingStateCubit;
  late final StreamSubscription<TradingStateViewState> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }

  // ── Watchlist CRUD ──────────────────────────────────────────────────────────

  Future<void> createWatchlist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final newWatchlist = Watchlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      symbols: const [],
    );
    final updated = [...state.watchlists, newWatchlist];
    await _persist(updated, selectedIndex: updated.length - 1);
  }

  Future<void> renameWatchlist(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final updated = [
      for (final w in state.watchlists)
        if (w.id == id) w.copyWith(name: trimmed) else w,
    ];
    await _persist(updated);
  }

  Future<void> deleteWatchlist(String id) async {
    if (state.watchlists.length <= 1) return; // always keep at least one
    final updated = state.watchlists.where((w) => w.id != id).toList();
    final nextIndex = state.selectedIndex.clamp(0, updated.length - 1);
    await _persist(updated, selectedIndex: nextIndex);
  }

  // ── Symbol operations ────────────────────────────────────────────────────────

  Future<void> addSymbol(String watchlistId, StockSymbol symbol) async {
    final updated = [
      for (final w in state.watchlists)
        if (w.id == watchlistId)
          w.copyWith(symbols: [...w.symbols, symbol])
        else
          w,
    ];
    await _persist(updated);
  }

  Future<void> removeSymbol(String watchlistId, StockSymbol symbol) async {
    final updated = [
      for (final w in state.watchlists)
        if (w.id == watchlistId)
          w.copyWith(symbols: w.symbols.where((s) => s != symbol).toList())
        else
          w,
    ];
    await _persist(updated);
  }

  Future<void> reorderSymbols(
    String watchlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final watchlist = state.watchlists.firstWhere((w) => w.id == watchlistId);
    final symbols = [...watchlist.symbols];
    final item = symbols.removeAt(oldIndex);
    symbols.insert(newIndex, item);
    final updated = [
      for (final w in state.watchlists)
        if (w.id == watchlistId) w.copyWith(symbols: symbols) else w,
    ];
    await _persist(updated);
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void selectWatchlist(int index) {
    emit(state.copyWith(selectedIndex: index));
  }

  // ── Sync from external TradingState changes ──────────────────────────────────

  void syncFrom(TradingState tradingState) {
    emit(state.copyWith(watchlists: tradingState.watchlists));
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  Future<void> _persist(
    List<Watchlist> watchlists, {
    int? selectedIndex,
  }) async {
    final currentTradingState = _tradingStateCubit.state.tradingState;
    if (currentTradingState == null) return;
    final nextTradingState = currentTradingState.copyWith(
      watchlists: watchlists,
    );
    await _tradingStateCubit.persist(nextTradingState);
    emit(
      state.copyWith(
        watchlists: watchlists,
        selectedIndex: selectedIndex ?? state.selectedIndex,
      ),
    );
  }
}
