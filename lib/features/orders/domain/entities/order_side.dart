enum OrderSide {
  buy,
  sell;

  static OrderSide fromValue(String value) {
    return OrderSide.values.firstWhere((side) => side.name == value);
  }
}
