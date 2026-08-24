import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../market/presentation/pages/market_overview_page.dart';
import '../../../watchlists/presentation/pages/watchlist_page.dart';
import '../cubit/home_navigation_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _titles = ['Market', 'Watchlists', 'Holdings'];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeNavigationCubit, int>(
      builder: (context, selectedIndex) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[selectedIndex]),
            actions: [
              // Debug speed toggle — only shown on the Market tab
              if (selectedIndex == 0) const MarketSpeedToggle(),
            ],
          ),
          body: switch (selectedIndex) {
            0 => const MarketOverviewPage(),
            1 => const WatchlistPage(),
            _ => const _PlannedFeature(message: 'Holdings are coming next.'),
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
            ],
          ),
        );
      },
    );
  }
}

class _PlannedFeature extends StatelessWidget {
  const _PlannedFeature({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
