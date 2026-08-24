import 'package:equatable/equatable.dart';

/// Immutable monetary amount stored in paise to avoid floating-point drift.
class Money extends Equatable implements Comparable<Money> {
  const Money.fromPaise(this.paise);

  const Money.fromRupees(int rupees) : paise = rupees * 100;

  static const zero = Money.fromPaise(0);

  final int paise;

  bool get isNegative => paise.isNegative;

  bool get isZero => paise == 0;

  Money operator +(Money other) => Money.fromPaise(paise + other.paise);

  Money operator -(Money other) => Money.fromPaise(paise - other.paise);

  Money multiply(int multiplier) => Money.fromPaise(paise * multiplier);

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  String get formatted {
    final absolutePaise = paise.abs();
    final rupees = absolutePaise ~/ 100;
    final fraction = (absolutePaise % 100).toString().padLeft(2, '0');
    final sign = isNegative ? '-' : '';
    return '$sign₹$rupees.$fraction';
  }

  @override
  List<Object> get props => [paise];
}
