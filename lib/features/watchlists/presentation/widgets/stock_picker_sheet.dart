import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/market_colors.dart';
import '../../../market/domain/entities/quote.dart';
import '../../../market/domain/entities/stock_symbol.dart';
import '../../../market/presentation/cubit/market_cubit.dart';
import '../cubit/watchlist_cubit.dart';

/// Bottom sheet that lists all 10 stocks for multi-selection. Already-added symbols are disabled.
class StockPickerSheet extends StatefulWidget {
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
  State<StockPickerSheet> createState() => _StockPickerSheetState();
}

class _StockPickerSheetState extends State<StockPickerSheet> {
  final Set<StockSymbol> _selectedSymbols = {};

  void _toggleSymbol(StockSymbol symbol) {
    setState(() {
      if (_selectedSymbols.contains(symbol)) {
        _selectedSymbols.remove(symbol);
      } else {
        _selectedSymbols.add(symbol);
      }
    });
  }

  void _toggleSelectAll(List<StockSymbol> availableSymbols) {
    setState(() {
      if (_selectedSymbols.length == availableSymbols.length) {
        _selectedSymbols.clear();
      } else {
        _selectedSymbols.addAll(availableSymbols);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final addedSymbols = context.select<WatchlistCubit, List<StockSymbol>>(
      (cubit) => cubit.state.watchlists
          .firstWhere(
            (w) => w.id == widget.watchlistId,
            orElse: () => cubit.state.watchlists.first,
          )
          .symbols,
    );

    final availableSymbols = StockSymbol.values
        .where((s) => !addedSymbols.contains(s))
        .toList();
    final allSelected =
        availableSymbols.isNotEmpty &&
        _selectedSymbols.length == availableSymbols.length;

    return SafeArea(
      child: Column(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Add Stocks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (availableSymbols.isNotEmpty)
                  TextButton(
                    onPressed: () => _toggleSelectAll(availableSymbols),
                    child: Text(allSelected ? 'Deselect All' : 'Select All'),
                  ),
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
                final isSelected = _selectedSymbols.contains(symbol);
                return _PickerRow(
                  symbol: symbol,
                  isAdded: isAdded,
                  isSelected: isSelected,
                  onTap: isAdded ? null : () => _toggleSymbol(symbol),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _selectedSymbols.isEmpty
                    ? null
                    : () {
                        context.read<WatchlistCubit>().addSymbols(
                          widget.watchlistId,
                          _selectedSymbols.toList(),
                        );
                        Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.add),
                label: Text(
                  _selectedSymbols.isEmpty
                      ? 'Select stocks to add'
                      : 'Add ${_selectedSymbols.length} ${_selectedSymbols.length == 1 ? 'Stock' : 'Stocks'}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.symbol,
    required this.isAdded,
    required this.isSelected,
    this.onTap,
  });

  final StockSymbol symbol;
  final bool isAdded;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MarketCubit, MarketState, Quote>(
      selector: (state) => state.quoteFor(symbol),
      builder: (context, quote) {
        final isGain = quote.change.paise >= 0;
        final color = isAdded
            ? Theme.of(context).colorScheme.outline
            : context.marketColors.forSign(isGain);

        return ListTile(
          onTap: onTap,
          enabled: !isAdded,
          selected: isSelected,
          leading: CircleAvatar(
            backgroundColor: isAdded
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              symbol.value.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAdded
                    ? Theme.of(context).colorScheme.outline
                    : isSelected
                    ? Theme.of(context).colorScheme.onPrimary
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
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
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
                    const SizedBox(width: 8),
                    Checkbox(
                      value: isSelected,
                      onChanged: onTap != null ? (_) => onTap!() : null,
                    ),
                  ],
                ),
        );
      },
    );
  }
}
