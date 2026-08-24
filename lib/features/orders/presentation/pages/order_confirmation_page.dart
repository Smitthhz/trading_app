import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_side.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({
    super.key,
    required this.order,
    required this.updatedBalance,
  });

  final Order order;
  final Money updatedBalance;

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == OrderSide.buy;
    final sideColor =
        isBuy ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final sideBg = isBuy ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final sideLabel = isBuy ? 'BUY' : 'SELL';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Success icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Order Executed!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sideBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sideLabel,
                    style: TextStyle(
                      color: sideColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Order detail card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Symbol',
                        value: order.symbol.value,
                        valueBold: true,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Quantity',
                        value: '${order.quantity} shares',
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Execution Price',
                        value: order.executionPrice.formatted,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Total Value',
                        value: order.value.formatted,
                        valueBold: true,
                        valueColor: sideColor,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Wallet Balance',
                        value: updatedBalance.formatted,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Executed At',
                        value: _formatTime(order.executedAt),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  // Pop back to home (remove ticket + confirmation from stack)
                  Navigator.of(context)
                    ..pop() // pop confirmation
                    ..pop(); // pop ticket
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Back to Home'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Place Another Order'),
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
    final s = dt.second.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m:$s';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool valueBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
            fontSize: valueBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
