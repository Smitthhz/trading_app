import '../entities/quote.dart';

abstract interface class MarketRepository {
  List<Quote> get currentQuotes;

  Stream<Quote> get quoteTicks;

  double get ticksPerSecond;

  bool get isRunning;

  void start();

  void stop();

  void configureTickRate(double ticksPerSecond);

  Future<void> dispose();
}
