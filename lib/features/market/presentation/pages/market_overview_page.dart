import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quote.dart';
import '../../domain/entities/stock_symbol.dart';
import '../cubit/market_cubit.dart';

class MarketOverviewPage extends StatelessWidget {
  const MarketOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: StockSymbol.values.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _QuoteRow(symbol: StockSymbol.values[index]);
      },
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.symbol});

  final StockSymbol symbol;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MarketCubit, MarketState, Quote>(
      selector: (state) => state.quoteFor(symbol),
      builder: (context, quote) {
        final isGain = quote.change.paise >= 0;
        final color = isGain ? Colors.green.shade700 : Colors.red.shade700;
        final percentage = _formatBasisPoints(quote.changeBasisPoints);

        return Card(
          child: ListTile(
            title: Text(quote.symbol.value),
            subtitle: Text(
              '${quote.change.formatted} ($percentage%)',
              style: TextStyle(color: color),
            ),
            trailing: Text(
              quote.lastTradedPrice.formatted,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      },
    );
  }

  String _formatBasisPoints(int value) {
    final sign = value.isNegative ? '-' : '';
    final absoluteValue = value.abs();
    final whole = absoluteValue ~/ 100;
    final fractional = (absoluteValue % 100).toString().padLeft(2, '0');
    return '$sign$whole.$fractional';
  }
}
