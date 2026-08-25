import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/market_colors.dart';
import '../../../../core/widgets/sparkline.dart';
import '../../domain/entities/stock_symbol.dart';
import '../cubit/market_cubit.dart';
import '../../../orders/presentation/pages/order_ticket_page.dart';

enum _MarketSort { name, priceDesc, changeDesc }

class MarketOverviewPage extends StatefulWidget {
  const MarketOverviewPage({super.key});

  @override
  State<MarketOverviewPage> createState() => _MarketOverviewPageState();
}

class _MarketOverviewPageState extends State<MarketOverviewPage> {
  final _searchController = TextEditingController();
  String _query = '';
  _MarketSort _sort = _MarketSort.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockSymbol> _visibleSymbols(MarketState marketState) {
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? StockSymbol.values.toList()
        : StockSymbol.values
              .where(
                (symbol) =>
                    symbol.value.toLowerCase().contains(query) ||
                    symbol.displayName.toLowerCase().contains(query),
              )
              .toList();

    switch (_sort) {
      case _MarketSort.name:
        matches.sort((a, b) => a.value.compareTo(b.value));
      case _MarketSort.priceDesc:
        matches.sort(
          (a, b) => marketState
              .quoteFor(b)
              .lastTradedPrice
              .compareTo(marketState.quoteFor(a).lastTradedPrice),
        );
      case _MarketSort.changeDesc:
        matches.sort(
          (a, b) => marketState
              .quoteFor(b)
              .changeBasisPoints
              .compareTo(marketState.quoteFor(a).changeBasisPoints),
        );
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search stocks',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _query = '';
                      }),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _SortChip(
                label: 'Name',
                selected: _sort == _MarketSort.name,
                onSelected: () => setState(() => _sort = _MarketSort.name),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Price',
                selected: _sort == _MarketSort.priceDesc,
                onSelected: () => setState(() => _sort = _MarketSort.priceDesc),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: '% Change',
                selected: _sort == _MarketSort.changeDesc,
                onSelected: () =>
                    setState(() => _sort = _MarketSort.changeDesc),
              ),
            ],
          ),
        ),
        Expanded(
          // Rebuilds on every tick regardless of sort mode — cheap for a
          // fixed 10-symbol list, and each row's own BlocConsumer already
          // avoids redundant subtree work. A buildWhen gate here would be
          // unsafe: flutter_bloc's BlocBuilder only refreshes its cached
          // state inside the buildWhen-gated listener, so gating out the
          // "Name" sort would render stale prices/order for a frame the
          // moment the user switches to a live sort.
          child: BlocBuilder<MarketCubit, MarketState>(
            builder: (context, marketState) {
              final symbols = _visibleSymbols(marketState);
              if (symbols.isEmpty) {
                return _NoResults(query: _query);
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: symbols.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final symbol = symbols[index];
                  return _QuoteRow(key: ValueKey(symbol.value), symbol: symbol);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No stocks match "$query"',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Per-symbol row with a green/red flash animation on every tick.
/// Uses [BlocConsumer] so:
///   - [buildWhen] ensures only this symbol's ticks trigger a rebuild
///   - [listenWhen] fires the flash animation on every tick for this symbol
class _QuoteRow extends StatefulWidget {
  const _QuoteRow({super.key, required this.symbol});

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
        final history = state.historyFor(widget.symbol);
        final isGain = quote.change.paise >= 0;
        final marketColors = context.marketColors;
        final trendColor = marketColors.forSign(isGain);
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
                  color: trendColor.withAlpha(
                    (_flashOpacity.value * 40).round(),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
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
                  child: Sparkline(values: history, color: trendColor),
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
                          color: trendColor,
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

/// Stop/resume button for the Market AppBar. Freezes every quote at its
/// last value when stopped; trading still works off that frozen snapshot.
class MarketFeedToggle extends StatelessWidget {
  const MarketFeedToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isRunning = context.select<MarketCubit, bool>(
      (cubit) => cubit.state.isFeedRunning,
    );
    return IconButton(
      tooltip: isRunning ? 'Stop live feed' : 'Resume live feed',
      icon: Icon(
        isRunning ? Icons.pause_circle_outline : Icons.play_circle_outline,
      ),
      onPressed: () => context.read<MarketCubit>().toggleFeed(),
    );
  }
}
