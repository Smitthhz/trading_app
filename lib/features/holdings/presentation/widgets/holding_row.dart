import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money.dart';
import '../../../../core/theme/market_colors.dart';
import '../../../../core/widgets/sparkline.dart';
import '../../../market/presentation/cubit/market_cubit.dart';
import '../../../orders/domain/entities/order_side.dart';
import '../../../orders/presentation/pages/order_ticket_page.dart';
import '../../domain/entities/holding.dart';
import '../cubit/holdings_cubit.dart';

/// A single holding row that subscribes to its own symbol's quote.
/// Uses BlocConsumer so the flash animation fires on every tick
/// without rebuilding the rest of the holdings list.
class HoldingRow extends StatefulWidget {
  const HoldingRow({super.key, required this.holding});

  final Holding holding;

  @override
  State<HoldingRow> createState() => _HoldingRowState();
}

class _HoldingRowState extends State<HoldingRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flashOpacity = CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _triggerFlash() {
    _flashController.forward(from: 0).then((_) => _flashController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.holding.symbol;
    return BlocConsumer<MarketCubit, MarketState>(
      listenWhen: (prev, curr) =>
          prev.quoteFor(symbol) != curr.quoteFor(symbol),
      listener: (context, state) => _triggerFlash(),
      buildWhen: (prev, curr) => prev.quoteFor(symbol) != curr.quoteFor(symbol),
      builder: (context, marketState) {
        final ltp = marketState.quoteFor(symbol).lastTradedPrice;
        final history = marketState.historyFor(symbol);
        final pnl = HoldingsCubit.pnl(widget.holding, ltp);
        final currentVal = HoldingsCubit.currentValue(widget.holding, ltp);
        final basisPoints = HoldingsCubit.pnlBasisPoints(widget.holding, ltp);
        final isGain = pnl.paise >= 0;
        final marketColors = context.marketColors;
        final pnlColor = marketColors.forSign(isGain);
        final flashColor = pnlColor;

        return AnimatedBuilder(
          animation: _flashOpacity,
          builder: (context, child) => Container(
            color: flashColor.withAlpha((_flashOpacity.value * 35).round()),
            child: child,
          ),
          child: InkWell(
            onTap: () => OrderTicketPage.push(context, symbol),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // ── Avatar ───────────────────────────────────────────────
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      symbol.value.substring(0, 1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Symbol + avg cost ─────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symbol.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${widget.holding.quantity} shares · avg ${widget.holding.averageCost.formatted}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Sparkline ──────────────────────────────────────────────
                  SizedBox(
                    width: 44,
                    height: 28,
                    child: Sparkline(values: history, color: pnlColor),
                  ),
                  const SizedBox(width: 8),
                  // ── Current value + P&L ───────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currentVal.formatted,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _PnLBadge(
                        pnl: pnl,
                        basisPoints: basisPoints,
                        isGain: isGain,
                      ),
                    ],
                  ),
                  // ── Quick trade arrows ────────────────────────────────────
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      _MiniTradeButton(
                        icon: Icons.add,
                        color: marketColors.gain,
                        onTap: () => OrderTicketPage.push(
                          context,
                          symbol,
                          initialSide: OrderSide.buy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _MiniTradeButton(
                        icon: Icons.remove,
                        color: marketColors.loss,
                        onTap: () => OrderTicketPage.push(
                          context,
                          symbol,
                          initialSide: OrderSide.sell,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PnLBadge extends StatelessWidget {
  const _PnLBadge({
    required this.pnl,
    required this.basisPoints,
    required this.isGain,
  });
  final Money pnl;
  final int basisPoints;
  final bool isGain;

  @override
  Widget build(BuildContext context) {
    final marketColors = context.marketColors;
    final color = marketColors.forSign(isGain);
    final bg = marketColors.containerForSign(isGain);
    final sign = isGain ? '+' : '';
    final pct = _fmtBp(basisPoints);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$sign${pnl.formatted} ($pct%)',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _fmtBp(int bp) {
    final sign = bp.isNegative ? '-' : '+';
    final abs = bp.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }
}

class _MiniTradeButton extends StatelessWidget {
  const _MiniTradeButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
