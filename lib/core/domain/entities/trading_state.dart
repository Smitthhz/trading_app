import 'package:equatable/equatable.dart';

import '../../../features/holdings/domain/entities/holding.dart';
import '../../../features/orders/domain/entities/order.dart';
import '../../../features/orders/domain/entities/wallet.dart';
import '../../../features/watchlists/domain/entities/watchlist.dart';

class TradingState extends Equatable {
  TradingState({
    required this.wallet,
    required List<Watchlist> watchlists,
    required List<Holding> holdings,
    required List<Order> orders,
  }) : watchlists = List.unmodifiable(watchlists),
       holdings = List.unmodifiable(holdings),
       orders = List.unmodifiable(orders);

  final Wallet wallet;
  final List<Watchlist> watchlists;
  final List<Holding> holdings;
  final List<Order> orders;

  TradingState copyWith({
    Wallet? wallet,
    List<Watchlist>? watchlists,
    List<Holding>? holdings,
    List<Order>? orders,
  }) {
    return TradingState(
      wallet: wallet ?? this.wallet,
      watchlists: watchlists ?? this.watchlists,
      holdings: holdings ?? this.holdings,
      orders: orders ?? this.orders,
    );
  }

  @override
  List<Object> get props => [wallet, watchlists, holdings, orders];
}
