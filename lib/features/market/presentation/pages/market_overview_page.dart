import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/stock_symbol.dart';
import '../cubit/market_cubit.dart';
import '../../../orders/presentation/pages/order_ticket_page.dart';

class MarketOverviewPage extends StatelessWidget {
  const MarketOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: StockSymbol.values.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        return _QuoteRow(symbol: StockSymbol.values[index]);
      },
    );
  }
}

/// Per-symbol row with a green/red flash animation on every tick.
/// Uses [BlocConsumer] so:
///   - [buildWhen] ensures only this symbol's ticks trigger a rebuild
///   - [listenWhen] fires the flash animation on every tick for this symbol
class _QuoteRow extends StatefulWidget {
  const _QuoteRow({required this.symbol});

  final StockSymbol symbol;

  @override
  State<_QuoteRow> createState() => _QuoteRowState();
}

class _QuoteRowState extends State<_QuoteRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController;
  late final Animation<double> _flashOpacity;

  static const _flashDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: _flashDuration,
    );
    _flashOpacity = CurvedAnimation(
      parent: _flashController,
      // Fade in quickly, fade out slowly
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
        final isGain = quote.change.paise >= 0;
        final flashColor =
            isGain ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        final changeColor = flashColor;
        final percentage = _formatBasisPoints(quote.changeBasisPoints);

        return AnimatedBuilder(
          animation: _flashOpacity,
          builder: (context, child) {
            return Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  // Flash overlay blended over the card surface
                  color: flashColor.withAlpha(
                    (_flashOpacity.value * 40).round(),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
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
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              widget.symbol.displayName,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isGain
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
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

/// Speed toggle button for the Market AppBar.
/// Placed in HomePage's AppBar when the Market tab is selected.
class MarketSpeedToggle extends StatelessWidget {
  const MarketSpeedToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isStress = context.select<MarketCubit, bool>(
      (cubit) => cubit.state.isStressMode,
    );
    return IconButton(
      tooltip: isStress ? 'Stress mode ON (5×/s)' : 'Standard mode (1×/s)',
      icon: Icon(
        isStress ? Icons.speed : Icons.slow_motion_video,
        color: isStress ? Colors.orange : null,
      ),
      onPressed: () => context.read<MarketCubit>().toggleStressMode(),
    );
  }
}
