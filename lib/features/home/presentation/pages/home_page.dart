import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/presentation/cubit/theme_cubit.dart';
import '../../../market/presentation/pages/market_overview_page.dart';
import '../../../orders/presentation/pages/order_history_page.dart';
import '../../../watchlists/presentation/pages/watchlist_page.dart';
import '../../../holdings/presentation/pages/holdings_page.dart';
import '../cubit/home_navigation_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _titles = ['Market', 'Watchlists', 'Holdings', 'Activity'];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeNavigationCubit, int>(
      builder: (context, selectedIndex) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[selectedIndex]),
            actions: [
              // Market-only controls — only shown on the Market tab
              if (selectedIndex == 0) ...[
                const MarketFeedToggle(),
                const MarketSpeedToggle(),
              ],
              const _ThemeToggleButton(),
            ],
          ),
          body: switch (selectedIndex) {
            0 => const MarketOverviewPage(),
            1 => const WatchlistPage(),
            2 => const HoldingsPage(),
            _ => const OrderHistoryPage(),
          },
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: context
                .read<HomeNavigationCubit>()
                .selectTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.candlestick_chart_outlined),
                selectedIcon: Icon(Icons.candlestick_chart),
                label: 'Market',
              ),
              NavigationDestination(
                icon: Icon(Icons.star_border),
                selectedIcon: Icon(Icons.star),
                label: 'Watchlists',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Holdings',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Activity',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Cycles system → light → dark on tap. The icon reflects the current
/// preference (not the resolved brightness) so the state is unambiguous.
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final (icon, tooltip) = switch (mode) {
          ThemeMode.system => (Icons.brightness_auto_outlined, 'Theme: system'),
          ThemeMode.light => (Icons.light_mode_outlined, 'Theme: light'),
          ThemeMode.dark => (Icons.dark_mode_outlined, 'Theme: dark'),
        };
        return IconButton(
          tooltip: tooltip,
          icon: Icon(icon),
          onPressed: context.read<ThemeCubit>().cycle,
        );
      },
    );
  }
}
