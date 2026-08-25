import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../market/presentation/cubit/market_cubit.dart';
import '../cubit/holdings_cubit.dart';
import '../widgets/holding_row.dart';
import '../widgets/holdings_summary_card.dart';

class HoldingsPage extends StatelessWidget {
  const HoldingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HoldingsCubit, HoldingsState>(
      builder: (context, holdingsState) {
        if (holdingsState.holdings.isEmpty) {
          return const HoldingsEmptyState();
        }

        return Column(
          children: [
            // ── Portfolio summary card ─────────────────────────────────────
            const HoldingsSummaryCard(),

            // ── Sort control ───────────────────────────────────────────────
            const HoldingsSortBar(),

            const Divider(height: 1),

            // ── Sorted holdings list ───────────────────────────────────────
            Expanded(
              child: BlocBuilder<MarketCubit, MarketState>(
                // Re-sort only when quotes for held symbols change
                buildWhen: (prev, curr) => holdingsState.holdings.any(
                  (h) => prev.quoteFor(h.symbol) != curr.quoteFor(h.symbol),
                ),
                builder: (context, marketState) {
                  final sorted = holdingsState.sortedFor(marketState);
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: sorted.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final holding = sorted[index];
                      return HoldingRow(
                        key: ValueKey(holding.symbol.value),
                        holding: holding,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
