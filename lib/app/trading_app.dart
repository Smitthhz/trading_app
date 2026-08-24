import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import 'di/service_locator.dart';
import 'presentation/cubit/trading_state_cubit.dart';
import '../features/home/presentation/cubit/home_navigation_cubit.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/market/presentation/cubit/market_cubit.dart';

class TradingApp extends StatelessWidget {
  const TradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => serviceLocator<HomeNavigationCubit>()),
        BlocProvider(create: (_) => serviceLocator<MarketCubit>()),
        BlocProvider(
          create: (_) => serviceLocator<TradingStateCubit>()..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Trading App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomePage(),
      ),
    );
  }
}
