import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../market/domain/entities/quote.dart';
import '../../../market/domain/entities/stock_symbol.dart';
import '../../../market/presentation/cubit/market_cubit.dart';
import '../cubit/watchlist_cubit.dart';

/// A single row in a watchlist showing a live quote for one symbol.
/// Uses BlocSelector scoped to this symbol — other symbols ticking
/// will not cause this widget to rebuild.
class WatchlistQuoteRow extends StatelessWidget {
  const WatchlistQuoteRow({
    super.key,
    required this.symbol,
    required this.watchlistId,
  });

  final StockSymbol symbol;
  final String watchlistId;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MarketCubit, MarketState, Quote>(
      selector: (state) => state.quoteFor(symbol),
      builder: (context, quote) {
        final isGain = quote.change.paise >= 0;
        final changeColor =
            isGain ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        final changeBg =
            isGain ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
        final percentage = _formatBasisPoints(quote.changeBasisPoints);

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              symbol.value.substring(0, 1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          title: Text(
            symbol.value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          subtitle: Text(
            symbol.displayName,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                quote.lastTradedPrice.formatted,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isGain ? '+' : ''}${quote.change.formatted} ($percentage%)',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          onTap: () {
            // Phase 4: navigate to order ticket
          },
        );
      },
    );
  }

  String _formatBasisPoints(int value) {
    final sign = value.isNegative ? '-' : '+';
    final absoluteValue = value.abs();
    final whole = absoluteValue ~/ 100;
    final fractional = (absoluteValue % 100).toString().padLeft(2, '0');
    return '$sign$whole.$fractional';
  }
}

/// Swipe-to-dismiss wrapper for [WatchlistQuoteRow].
class DismissibleWatchlistRow extends StatelessWidget {
  const DismissibleWatchlistRow({
    super.key,
    required this.symbol,
    required this.watchlistId,
  });

  final StockSymbol symbol;
  final String watchlistId;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(symbol.value),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) {
        context.read<WatchlistCubit>().removeSymbol(watchlistId, symbol);
      },
      child: WatchlistQuoteRow(symbol: symbol, watchlistId: watchlistId),
    );
  }
}
