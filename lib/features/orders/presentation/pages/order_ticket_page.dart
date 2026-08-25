import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/presentation/cubit/trading_state_cubit.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/market_colors.dart';
import '../../../market/domain/entities/stock_symbol.dart';
import '../../../market/domain/repositories/market_repository.dart';
import '../../../market/presentation/cubit/market_cubit.dart';
import '../../domain/entities/order_side.dart';
import '../../domain/usecases/execute_order.dart';
import '../bloc/order_bloc.dart';
import 'order_confirmation_page.dart';

class OrderTicketPage extends StatelessWidget {
  const OrderTicketPage({
    super.key,
    required this.symbol,
    this.initialSide = OrderSide.buy,
  });

  final StockSymbol symbol;
  final OrderSide initialSide;

  /// Push this page onto the navigator stack.
  ///
  /// No-ops (with a snackbar) if the persisted trading state hasn't finished
  /// its initial async load yet — [OrderBloc] requires it to seed the ticket.
  static Future<void> push(
    BuildContext context,
    StockSymbol symbol, {
    OrderSide initialSide = OrderSide.buy,
  }) {
    final tradingState = context.read<TradingStateCubit>().state.tradingState;
    if (tradingState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App state not ready. Please try again.')),
      );
      return Future.value();
    }

    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<MarketCubit>()),
            BlocProvider(
              create: (_) => OrderBloc(
                symbol: symbol,
                initialSide: initialSide,
                initialTradingState: tradingState,
                tradingStateCubit: context.read<TradingStateCubit>(),
                marketRepository: context.read<MarketRepository>(),
                executeOrder: ExecuteOrder(),
              ),
            ),
          ],
          child: OrderTicketPage(symbol: symbol, initialSide: initialSide),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listenWhen: (_, curr) => curr is OrderSucceeded || curr is OrderFailed,
      listener: (context, state) {
        if (state is OrderSucceeded) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderConfirmationPage(
                order: state.order,
                updatedBalance: state.newState.wallet.availableBalance,
              ),
            ),
          );
        } else if (state is OrderFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(symbol.value)),
        body: _TicketBody(symbol: symbol),
      ),
    );
  }
}

class _TicketBody extends StatefulWidget {
  const _TicketBody({required this.symbol});
  final StockSymbol symbol;

  @override
  State<_TicketBody> createState() => _TicketBodyState();
}

class _TicketBodyState extends State<_TicketBody> {
  final _quantityController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        final isSubmitting = state is OrderSubmitting;
        final editing = state is OrderEditing ? state : null;
        final isBuy = (editing?.side ?? OrderSide.buy) == OrderSide.buy;
        final sideColor = context.marketColors.forSign(isBuy);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Symbol Header ─────────────────────────────────────────────
              _SymbolHeader(symbol: widget.symbol),
              const SizedBox(height: 24),

              // ── Buy / Sell Toggle ─────────────────────────────────────────
              _SideToggle(
                isBuy: isBuy,
                onToggle: isSubmitting
                    ? null
                    : () => context.read<OrderBloc>().add(
                        const OrderSideToggled(),
                      ),
              ),
              const SizedBox(height: 24),

              // ── Quantity Input ────────────────────────────────────────────
              TextField(
                controller: _quantityController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Quantity (shares)',
                  hintText: 'e.g. 10',
                  border: const OutlineInputBorder(),
                  errorText: editing?.parseError,
                  suffixText: 'shares',
                ),
                onChanged: (val) =>
                    context.read<OrderBloc>().add(OrderQuantityChanged(val)),
              ),
              const SizedBox(height: 20),

              // ── Live projected value & balance/holding info ───────────────
              _LiveProjection(
                symbol: widget.symbol,
                isBuy: isBuy,
                rawQuantity: editing?.rawQuantity ?? '',
                walletBalance: editing?.walletBalance,
                heldQuantity: editing?.heldQuantity,
                sideColor: sideColor,
              ),
              const SizedBox(height: 32),

              // ── Submit Button ─────────────────────────────────────────────
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: sideColor,
                ),
                onPressed: isSubmitting || !(editing?.canSubmit ?? false)
                    ? null
                    : () => context.read<OrderBloc>().add(
                        const OrderSubmitRequested(),
                      ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isBuy ? 'Place Buy Order' : 'Place Sell Order',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Symbol Header (live LTP via BlocSelector) ─────────────────────────────────

class _SymbolHeader extends StatelessWidget {
  const _SymbolHeader({required this.symbol});
  final StockSymbol symbol;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      MarketCubit,
      MarketState,
      ({Money ltp, Money change, int basisPoints})
    >(
      selector: (state) {
        final q = state.quoteFor(symbol);
        return (
          ltp: q.lastTradedPrice,
          change: q.change,
          basisPoints: q.changeBasisPoints,
        );
      },
      builder: (context, data) {
        final isGain = data.change.paise >= 0;
        final changeColor = context.marketColors.forSign(isGain);
        final pct = _fmtBp(data.basisPoints);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  symbol.value.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      symbol.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.ltp.formatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    '${isGain ? '+' : ''}${data.change.formatted} ($pct%)',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtBp(int value) {
    final sign = value.isNegative ? '-' : '+';
    final abs = value.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }
}

// ── Live Projection (quantity × LTP) ──────────────────────────────────────────

class _LiveProjection extends StatelessWidget {
  const _LiveProjection({
    required this.symbol,
    required this.isBuy,
    required this.rawQuantity,
    required this.sideColor,
    this.walletBalance,
    this.heldQuantity,
  });

  final StockSymbol symbol;
  final bool isBuy;
  final String rawQuantity;
  final Color sideColor;
  final Money? walletBalance;
  final int? heldQuantity;

  @override
  Widget build(BuildContext context) {
    final qty = int.tryParse(rawQuantity.trim()) ?? 0;

    return BlocSelector<MarketCubit, MarketState, Money>(
      selector: (state) => state.quoteFor(symbol).lastTradedPrice,
      builder: (context, ltp) {
        final projected = qty > 0 ? ltp.multiply(qty) : Money.zero;
        final canAfford =
            walletBalance == null || walletBalance!.compareTo(projected) >= 0;
        final enoughShares = heldQuantity == null || heldQuantity! >= qty;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _InfoRow(
                label: 'Projected Value',
                value: qty > 0 ? projected.formatted : '—',
                valueColor: qty > 0 ? sideColor : null,
                bold: true,
              ),
              const SizedBox(height: 10),
              if (isBuy) ...[
                _InfoRow(
                  label: 'Available Balance',
                  value: walletBalance?.formatted ?? '—',
                  valueColor: !canAfford && qty > 0
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                if (!canAfford && qty > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Insufficient balance',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                _InfoRow(
                  label: 'Shares You Hold',
                  value: heldQuantity != null ? '$heldQuantity shares' : '—',
                  valueColor: !enoughShares && qty > 0
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                if (!enoughShares && qty > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Not enough shares to sell',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
            fontSize: bold ? 15 : 13,
          ),
        ),
      ],
    );
  }
}

// ── Buy/Sell Toggle ────────────────────────────────────────────────────────────

class _SideToggle extends StatelessWidget {
  const _SideToggle({required this.isBuy, this.onToggle});
  final bool isBuy;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _SideButton(
              label: 'BUY',
              selected: isBuy,
              color: context.marketColors.gain,
              onTap: isBuy ? null : onToggle,
            ),
          ),
          Expanded(
            child: _SideButton(
              label: 'SELL',
              selected: !isBuy,
              color: context.marketColors.loss,
              onTap: !isBuy ? null : onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.label,
    required this.selected,
    required this.color,
    this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
