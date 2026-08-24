import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../market/domain/entities/stock_symbol.dart';
import '../../domain/entities/watchlist.dart';
import '../cubit/watchlist_cubit.dart';
import '../widgets/stock_picker_sheet.dart';
import '../widgets/watchlist_quote_row.dart';

/// The body for a single watchlist. Shows an empty state if it has no symbols,
/// otherwise a reorderable + dismissible list of live quote rows.
class WatchlistBody extends StatelessWidget {
  const WatchlistBody({super.key, required this.watchlist});

  final Watchlist watchlist;

  @override
  Widget build(BuildContext context) {
    if (watchlist.symbols.isEmpty) {
      return _EmptyState(watchlistId: watchlist.id);
    }

    return Stack(
      children: [
        ReorderableListView.builder(
          padding: const EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: 80, // space for FAB
          ),
          itemCount: watchlist.symbols.length,
          onReorder: (oldIndex, newIndex) {
            context
                .read<WatchlistCubit>()
                .reorderSymbols(watchlist.id, oldIndex, newIndex);
          },
          buildDefaultDragHandles: false,
          itemBuilder: (context, index) {
            final symbol = watchlist.symbols[index];
            return _ReorderableRow(
              key: ValueKey(symbol.value),
              symbol: symbol,
              watchlistId: watchlist.id,
              index: index,
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add_stock_${watchlist.id}',
            onPressed: () =>
                StockPickerSheet.show(context, watchlist.id),
            icon: const Icon(Icons.add),
            label: const Text('Add Stock'),
          ),
        ),
      ],
    );
  }
}

/// Wraps [DismissibleWatchlistRow] inside the ReorderableListView.
/// The drag handle is shown on the trailing edge.
class _ReorderableRow extends StatelessWidget {
  const _ReorderableRow({
    super.key,
    required this.symbol,
    required this.watchlistId,
    required this.index,
  });

  final StockSymbol symbol;
  final String watchlistId;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: DismissibleWatchlistRow(
              symbol: symbol,
              watchlistId: watchlistId,
            ),
          ),
          // The drag handle must be outside the Dismissible
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.drag_handle, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.watchlistId});

  final String watchlistId;

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
                Icons.star_border_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No stocks yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your favourite stocks to track their live prices here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => StockPickerSheet.show(context, watchlistId),
              icon: const Icon(Icons.add),
              label: const Text('Add Stocks'),
            ),
          ],
        ),
      ),
    );
  }
}
