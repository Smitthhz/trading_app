import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/presentation/cubit/trading_state_cubit.dart';
import '../../../../core/theme/market_colors.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_side.dart';
import 'order_ticket_page.dart';

/// Read-only list of every executed order, most recent first.
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TradingStateCubit, TradingStateViewState>(
      builder: (context, state) {
        final orders = state.tradingState?.orders ?? const <Order>[];
        if (orders.isEmpty) {
          return const _EmptyState();
        }

        final sorted = [...orders]
          ..sort((a, b) => b.executedAt.compareTo(a.executedAt));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sorted.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _OrderTile(order: sorted[index]),
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == OrderSide.buy;
    final sideColor = context.marketColors.forSign(isBuy);
    final sideBg = context.marketColors.containerForSign(isBuy);

    return Card(
      child: InkWell(
        onTap: () => OrderTicketPage.push(
          context,
          order.symbol,
          initialSide: order.side,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sideBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isBuy
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: sideColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.symbol.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBuy ? 'BUY' : 'SELL',
                          style: TextStyle(
                            color: sideColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.quantity} shares @ ${order.executionPrice.formatted}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order.value.formatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(order.executedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No orders yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your executed buy and sell orders will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
