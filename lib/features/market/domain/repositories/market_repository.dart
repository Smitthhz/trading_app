import '../entities/quote.dart';

abstract interface class MarketRepository {
  List<Quote> get currentQuotes;

  Stream<Quote> get quoteTicks;

  double get ticksPerSecond;

  void start();

  void configureTickRate(double ticksPerSecond);

  Future<void> dispose();
}
