import 'dart:math';

/// Formats a score or total for display. Whole numbers have no decimal point;
/// only totals that include a 10.1 show one decimal place (e.g. 95 or 95.2).
String formatScore(double value) {
  final tenths = (value * 10).round();
  return tenths % 10 == 0
      ? (tenths ~/ 10).toString()
      : (tenths / 10).toStringAsFixed(1);
}

enum TargetType {
  airPistol,
  airRifle,
}

class Shot {
  final double x;
  final double y;
  final double score;
  final double decimalScore;
  final bool isInnerTen;
  final DateTime timestamp;

  /// Pellet (hole) radius in mm - 4.5mm calibre.
  static const double pelletRadius = 2.25;

  /// 10-ring diameters in mm.
  static const double pistolTenRingDiameter = 11.5;
  static const double rifleTenRingDiameter = 0.5;

  /// Hole centre within this distance (mm) of the target centre takes out the
  /// centre pip and scores the club-standard 10.1.
  static const double innerTenRadius = 2.24;
  static const double innerTenDecimalScore = 10.1;

  Shot(this.x, this.y, this.score, this.decimalScore, this.isInnerTen,
      this.timestamp);

  factory Shot.fromJson(Map<String, dynamic> json, TargetType targetType) {
    final double x = (json['x'] as num).toDouble();
    final double y = (json['y'] as num).toDouble();

    // x/y is the centre of the pellet hole. The hole is 4.5mm wide, so if its
    // edge touches a ring line the higher score counts. Equivalently, each
    // ring boundary is pushed out by the pellet radius.
    final distance = sqrt(pow(x, 2) + pow(y, 2));

    // Width of one scoring ring, measured from the hole centre:
    // (10-ring radius + pellet radius). Pistol rings are 8mm wide, rifle 2.5mm.
    final double ringWidth = (targetType == TargetType.airPistol
            ? pistolTenRingDiameter
            : rifleTenRingDiameter) /
            2 +
        pelletRadius;

    // Anything that takes out the centre pip scores the club-standard 10.1.
    final bool isInnerTen = distance <= innerTenRadius;

    // Ring score counting high: 10 as soon as the hole touches the 10 ring,
    // then one whole point per ringWidth outwards.
    double rawScore = 11 - (distance / ringWidth);
    rawScore = rawScore.clamp(0.0, 10.0);

    final double score = rawScore.floorToDouble();

    // The only decimal score is the club-standard 10.1; everything else is a
    // whole number.
    final double decimalScore = isInnerTen ? innerTenDecimalScore : score;

    return Shot(x, -y, score, decimalScore, isInnerTen, DateTime.now());
  }
}