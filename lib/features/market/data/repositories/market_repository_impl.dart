import '../../domain/entities/quote.dart';
import '../../domain/repositories/market_repository.dart';
import '../datasources/mock_market_data_feed.dart';

class MarketRepositoryImpl implements MarketRepository {
  MarketRepositoryImpl({required MockMarketDataFeed feed}) : _feed = feed;

  final MockMarketDataFeed _feed;

  @override
  List<Quote> get currentQuotes => _feed.currentQuotes;

  @override
  Stream<Quote> get quoteTicks => _feed.ticks;

  @override
  double get ticksPerSecond => _feed.ticksPerSecondPerStock;

  @override
  void start() => _feed.start();

  @override
  void configureTickRate(double ticksPerSecond) =>
      _feed.configureTickRate(ticksPerSecond);

  @override
  Future<void> dispose() => _feed.dispose();
}
