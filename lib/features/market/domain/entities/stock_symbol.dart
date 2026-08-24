enum StockSymbol {
  reliance('RELIANCE', 'Reliance Industries'),
  tcs('TCS', 'Tata Consultancy Services'),
  infy('INFY', 'Infosys'),
  hdfcBank('HDFCBANK', 'HDFC Bank'),
  iciciBank('ICICIBANK', 'ICICI Bank'),
  sbin('SBIN', 'State Bank of India'),
  itc('ITC', 'ITC Limited'),
  lt('LT', 'Larsen & Toubro'),
  bhartiAirtel('BHARTIARTL', 'Bharti Airtel'),
  axisBank('AXISBANK', 'Axis Bank');

  const StockSymbol(this.value, this.displayName);

  final String value;
  final String displayName;

  static StockSymbol fromValue(String value) {
    return StockSymbol.values.firstWhere((symbol) => symbol.value == value);
  }
}
