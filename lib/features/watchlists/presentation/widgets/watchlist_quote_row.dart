import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/market_colors.dart';
import '../../../../core/widgets/sparkline.dart';
import '../../../market/domain/entities/stock_symbol.dart';
import '../../../market/presentation/cubit/market_cubit.dart';
import '../../../orders/presentation/pages/order_ticket_page.dart';
import '../cubit/watchlist_cubit.dart';

/// A single row in a watchlist showing a live quote for one symbol.
/// Uses [BlocConsumer] scoped to this symbol:
///   - [buildWhen] prevents rebuilds when other symbols tick
///   - [listenWhen] triggers a green/red flash animation on every tick
class WatchlistQuoteRow extends StatefulWidget {
  const WatchlistQuoteRow({
    super.key,
    required this.symbol,
    required this.watchlistId,
  });

  final StockSymbol symbol;
  final String watchlistId;

  @override
  State<WatchlistQuoteRow> createState() => _WatchlistQuoteRowState();
}

class _WatchlistQuoteRowState extends State<WatchlistQuoteRow>
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
    return BlocConsumer<MarketCubit, MarketState>(
      listenWhen: (prev, curr) =>
          prev.quoteFor(widget.symbol) != curr.quoteFor(widget.symbol),
      listener: (context, state) => _triggerFlash(),
      buildWhen: (prev, curr) =>
          prev.quoteFor(widget.symbol) != curr.quoteFor(widget.symbol),
      builder: (context, state) {
        final quote = state.quoteFor(widget.symbol);
        final history = state.historyFor(widget.symbol);
        final isGain = quote.change.paise >= 0;
        final marketColors = context.marketColors;
        final flashColor = marketColors.forSign(isGain);
        final changeColor = flashColor;
        final percentage = _formatBasisPoints(quote.changeBasisPoints);

        return AnimatedBuilder(
          animation: _flashOpacity,
          builder: (context, child) => Ink(
            color: flashColor.withAlpha((_flashOpacity.value * 40).round()),
            child: child,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                widget.symbol.value.substring(0, 1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            title: Text(
              widget.symbol.value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Text(
              widget.symbol.displayName,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 28,
                  child: Sparkline(values: history, color: flashColor),
                ),
                const SizedBox(width: 8),
                Column(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: marketColors.containerForSign(isGain),
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
              ],
            ),
            onTap: () => OrderTicketPage.push(context, widget.symbol),
          ),
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
