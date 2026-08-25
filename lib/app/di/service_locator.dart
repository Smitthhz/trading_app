import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/shared_preferences_trading_state_repository.dart';
import '../../core/domain/repositories/trading_state_repository.dart';
import '../../features/home/presentation/cubit/home_navigation_cubit.dart';
import '../../features/market/data/datasources/mock_market_data_feed.dart';
import '../../features/market/data/repositories/market_repository_impl.dart';
import '../../features/market/domain/repositories/market_repository.dart';
import '../../features/market/presentation/cubit/market_cubit.dart';
import '../presentation/cubit/theme_cubit.dart';
import '../presentation/cubit/trading_state_cubit.dart';
import '../../features/watchlists/presentation/cubit/watchlist_cubit.dart';
import '../../features/holdings/presentation/cubit/holdings_cubit.dart';
import '../seed/app_seed.dart';

final serviceLocator = GetIt.instance;

Future<void> configureDependencies({SharedPreferences? preferences}) async {
  if (serviceLocator.isRegistered<AppSeed>()) {
    return;
  }

  final resolvedPreferences =
      preferences ?? await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(resolvedPreferences);
  serviceLocator.registerLazySingleton(AppSeed.initial);
  serviceLocator.registerLazySingleton<TradingStateRepository>(
    () => SharedPreferencesTradingStateRepository(
      preferences: serviceLocator(),
      fallbackState: serviceLocator<AppSeed>().tradingState,
    ),
  );
  serviceLocator.registerLazySingleton(
    () => MockMarketDataFeed(
      initialQuotes: serviceLocator<AppSeed>().marketQuotes,
    ),
  );
  serviceLocator.registerLazySingleton<MarketRepository>(
    () => MarketRepositoryImpl(feed: serviceLocator()),
  );
  serviceLocator.registerFactory(HomeNavigationCubit.new);
  serviceLocator.registerFactory(
    () => MarketCubit(repository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => TradingStateCubit(repository: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => WatchlistCubit(tradingStateCubit: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => HoldingsCubit(tradingStateCubit: serviceLocator()),
  );
  serviceLocator.registerFactory(
    () => ThemeCubit(preferences: serviceLocator()),
  );
}
