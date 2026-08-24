import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

class Wallet extends Equatable {
  const Wallet({required this.availableBalance});

  final Money availableBalance;

  Wallet copyWith({Money? availableBalance}) {
    return Wallet(availableBalance: availableBalance ?? this.availableBalance);
  }

  @override
  List<Object> get props => [availableBalance];
}
