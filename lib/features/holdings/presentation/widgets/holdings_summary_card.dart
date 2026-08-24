import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../market/presentation/cubit/market_cubit.dart';
import '../cubit/holdings_cubit.dart';

/// Portfolio summary card — total invested, current value, and total P&L.
/// Subscribes to [MarketCubit] scoped to only the held symbols so it
/// updates live without rebuilding the holdings list.
class HoldingsSummaryCard extends StatelessWidget {
  const HoldingsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HoldingsCubit, HoldingsState>(
      builder: (context, holdingsState) {
        if (holdingsState.holdings.isEmpty) return const SizedBox.shrink();

        return BlocBuilder<MarketCubit, MarketState>(
          buildWhen: (prev, curr) => holdingsState.holdings.any(
            (h) => prev.quoteFor(h.symbol) != curr.quoteFor(h.symbol),
          ),
          builder: (context, marketState) {
            final summary = holdingsState.summaryFor(marketState);
            final isGain = summary.pnl.paise >= 0;
            final pct = _fmtBp(summary.pnlBasisPoints);
            final sign = isGain ? '+' : '';

            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isGain
                      ? [const Color(0xFF1D4ED8), const Color(0xFF047857)]
                      : [const Color(0xFF1D4ED8), const Color(0xFF9F1239)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Portfolio Value',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.currentValue.formatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Invested',
                          value: summary.totalInvested.formatted,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white24,
                      ),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Total P&L',
                          value:
                              '$sign${summary.pnl.formatted} ($pct%)',
                          valueColor: isGain
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _fmtBp(int bp) {
    final sign = bp.isNegative ? '-' : '+';
    final abs = bp.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal sort-order chip row.
class HoldingsSortBar extends StatelessWidget {
  const HoldingsSortBar({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context
        .select<HoldingsCubit, HoldingSortOrder>((c) => c.state.sortOrder);
    final cubit = context.read<HoldingsCubit>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _SortChip(
            label: 'P&L ↓',
            selected: current == HoldingSortOrder.pnlDescending,
            onTap: () => cubit.setSortOrder(HoldingSortOrder.pnlDescending),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'P&L ↑',
            selected: current == HoldingSortOrder.pnlAscending,
            onTap: () => cubit.setSortOrder(HoldingSortOrder.pnlAscending),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Symbol A–Z',
            selected: current == HoldingSortOrder.symbolAz,
            onTap: () => cubit.setSortOrder(HoldingSortOrder.symbolAz),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Value ↓',
            selected: current == HoldingSortOrder.valueDescending,
            onTap: () => cubit.setSortOrder(HoldingSortOrder.valueDescending),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Empty state shown when no holdings exist.
class HoldingsEmptyState extends StatelessWidget {
  const HoldingsEmptyState({super.key});

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
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Holdings Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Buy stocks from the Market or Watchlist tabs to start building your portfolio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
