import 'package:flutter/material.dart';

/// Semantic gain/loss colors, themed separately for light and dark so
/// badge backgrounds stay legible in both — a flat hex like `#DCFCE7`
/// reads fine on a white surface but washes out on a dark one.
@immutable
class MarketColors extends ThemeExtension<MarketColors> {
  const MarketColors({
    required this.gain,
    required this.loss,
    required this.gainContainer,
    required this.lossContainer,
  });

  final Color gain;
  final Color loss;
  final Color gainContainer;
  final Color lossContainer;

  static const light = MarketColors(
    gain: Color(0xFF15803D),
    loss: Color(0xFFDC2626),
    gainContainer: Color(0xFFDCFCE7),
    lossContainer: Color(0xFFFEE2E2),
  );

  static const dark = MarketColors(
    gain: Color(0xFF4ADE80),
    loss: Color(0xFFF87171),
    gainContainer: Color(0xFF14532D),
    lossContainer: Color(0xFF7F1D1D),
  );

  Color forSign(bool isGain) => isGain ? gain : loss;

  Color containerForSign(bool isGain) => isGain ? gainContainer : lossContainer;

  @override
  MarketColors copyWith({
    Color? gain,
    Color? loss,
    Color? gainContainer,
    Color? lossContainer,
  }) {
    return MarketColors(
      gain: gain ?? this.gain,
      loss: loss ?? this.loss,
      gainContainer: gainContainer ?? this.gainContainer,
      lossContainer: lossContainer ?? this.lossContainer,
    );
  }

  @override
  MarketColors lerp(ThemeExtension<MarketColors>? other, double t) {
    if (other is! MarketColors) return this;
    return MarketColors(
      gain: Color.lerp(gain, other.gain, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      gainContainer: Color.lerp(gainContainer, other.gainContainer, t)!,
      lossContainer: Color.lerp(lossContainer, other.lossContainer, t)!,
    );
  }
}

extension MarketColorsContext on BuildContext {
  MarketColors get marketColors =>
      Theme.of(this).extension<MarketColors>() ?? MarketColors.light;
}
