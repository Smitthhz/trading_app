part of 'watchlist_cubit.dart';

class WatchlistState extends Equatable {
  const WatchlistState({required this.watchlists, required this.selectedIndex});

  final List<Watchlist> watchlists;
  final int selectedIndex;

  Watchlist? get selectedWatchlist =>
      watchlists.isEmpty ? null : watchlists[selectedIndex];

  WatchlistState copyWith({List<Watchlist>? watchlists, int? selectedIndex}) {
    return WatchlistState(
      watchlists: watchlists ?? this.watchlists,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  @override
  List<Object> get props => [watchlists, selectedIndex];
}
