enum StockSymbol {
  reliance('RELIANCE'),
  tcs('TCS'),
  infy('INFY'),
  hdfcBank('HDFCBANK'),
  iciciBank('ICICIBANK'),
  sbin('SBIN'),
  itc('ITC'),
  lt('LT'),
  bhartiAirtel('BHARTIARTL'),
  axisBank('AXISBANK');

  const StockSymbol(this.value);

  final String value;

  static StockSymbol fromValue(String value) {
    return StockSymbol.values.firstWhere((symbol) => symbol.value == value);
  }
}
