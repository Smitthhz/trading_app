import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../market/domain/entities/quote.dart';
import '../../../market/domain/entities/stock_symbol.dart';
import '../../../market/presentation/cubit/market_cubit.dart';
import '../cubit/watchlist_cubit.dart';

/// Bottom sheet that lists all 10 stocks. Already-added symbols are disabled.
class StockPickerSheet extends StatelessWidget {
  const StockPickerSheet({super.key, required this.watchlistId});

  final String watchlistId;

  static Future<void> show(BuildContext context, String watchlistId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<WatchlistCubit>(),
        child: BlocProvider.value(
          value: context.read<MarketCubit>(),
          child: StockPickerSheet(watchlistId: watchlistId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addedSymbols = context
        .select<WatchlistCubit, List<StockSymbol>>(
          (cubit) => cubit.state.watchlists
              .firstWhere(
                (w) => w.id == watchlistId,
                orElse: () => cubit.state.watchlists.first,
              )
              .symbols,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Add Stocks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: StockSymbol.values.length,
            itemBuilder: (context, index) {
              final symbol = StockSymbol.values[index];
              final isAdded = addedSymbols.contains(symbol);
              return _PickerRow(
                symbol: symbol,
                isAdded: isAdded,
                onTap: isAdded
                    ? null
                    : () {
                        context
                            .read<WatchlistCubit>()
                            .addSymbol(watchlistId, symbol);
                        Navigator.of(context).pop();
                      },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.symbol,
    required this.isAdded,
    this.onTap,
  });

  final StockSymbol symbol;
  final bool isAdded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MarketCubit, MarketState, Quote>(
      selector: (state) => state.quoteFor(symbol),
      builder: (context, quote) {
        final isGain = quote.change.paise >= 0;
        final color = isAdded
            ? Theme.of(context).colorScheme.outline
            : isGain
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626);

        return ListTile(
          onTap: onTap,
          enabled: !isAdded,
          leading: CircleAvatar(
            backgroundColor: isAdded
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              symbol.value.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAdded
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          title: Text(
            symbol.value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(symbol.displayName),
          trailing: isAdded
              ? Chip(
                  label: const Text('Added'),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  side: BorderSide.none,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      quote.lastTradedPrice.formatted,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      quote.change.formatted,
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
