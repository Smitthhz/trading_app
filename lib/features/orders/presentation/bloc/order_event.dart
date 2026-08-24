part of 'order_bloc.dart';

sealed class OrderEvent extends Equatable {
  const OrderEvent();
}

class OrderSideToggled extends OrderEvent {
  const OrderSideToggled();
  @override
  List<Object> get props => [];
}

class OrderQuantityChanged extends OrderEvent {
  const OrderQuantityChanged(this.raw);
  final String raw;
  @override
  List<Object> get props => [raw];
}

class OrderSubmitRequested extends OrderEvent {
  const OrderSubmitRequested();
  @override
  List<Object> get props => [];
}
