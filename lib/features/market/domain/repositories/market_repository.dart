import '../entities/quote.dart';

abstract interface class MarketRepository {
  List<Quote> get currentQuotes;

  Stream<Quote> get quoteTicks;

  void start();

  Future<void> dispose();
}
