import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_shot_app/models/shot.dart';

Shot pistol(double x, double y) =>
    Shot.fromJson({'x': x, 'y': y}, TargetType.airPistol);
Shot rifle(double x, double y) =>
    Shot.fromJson({'x': x, 'y': y}, TargetType.airRifle);

void main() {
  group('Pistol scoring (counting high, club 10.1)', () {
    test('taking out the centre pip scores 10.1', () {
      expect(pistol(0, 0).decimalScore, 10.1);
      expect(pistol(2.24, 0).decimalScore, 10.1);
      expect(pistol(0, 2.24).score, 10);
      expect(pistol(2.24, 0).isInnerTen, isTrue);
    });

    test('just outside the pip but inside the 10 ring scores a whole 10', () {
      final shot = pistol(2.5, 0);
      expect(shot.isInnerTen, isFalse);
      expect(shot.decimalScore, 10);
      expect(shot.score, 10);
    });

    test('hole edge clipping the 10 ring scores 10', () {
      // 10 ring radius 5.75mm + 2.25mm pellet radius = 8.0mm
      expect(pistol(8.0, 0).score, 10);
      expect(pistol(8.0, 0).decimalScore, 10);
      expect(pistol(8.1, 0).score, 9);
      expect(pistol(8.1, 0).decimalScore, 9);
    });

    test('hole edge clipping the 9 ring scores 9', () {
      // 9 ring radius 13.75mm + 2.25mm = 16.0mm
      expect(pistol(16.0, 0).score, 9);
      expect(pistol(16.0, 0).decimalScore, 9);
      expect(pistol(16.1, 0).score, 8);
    });

    test('shot far off the target never scores below zero', () {
      final shot = pistol(500, 500);
      expect(shot.decimalScore, 0);
      expect(shot.score, 0);
    });

    test('10.1 is the only non-whole score', () {
      for (var d = 0.0; d < 100; d += 0.37) {
        final s = pistol(d, 0);
        if (s.decimalScore != 10.1) {
          expect(s.decimalScore, s.decimalScore.roundToDouble());
        }
      }
    });
  });

  group('Rifle scoring', () {
    test('taking out the centre pip scores 10.1', () {
      expect(rifle(0, 0).decimalScore, 10.1);
      expect(rifle(2.24, 0).decimalScore, 10.1);
    });

    test('hole edge clipping the 10 ring scores 10', () {
      // 10 ring radius 0.25mm + 2.25mm = 2.5mm
      expect(rifle(2.5, 0).score, 10);
      expect(rifle(2.5, 0).decimalScore, 10);
      expect(rifle(2.6, 0).score, 9);
      expect(rifle(2.6, 0).decimalScore, 9);
    });

    test('misses never score below zero', () {
      expect(rifle(100, 0).decimalScore, 0);
    });
  });

  group('formatScore', () {
    test('whole numbers have no decimal point', () {
      expect(formatScore(9), '9');
      expect(formatScore(95), '95');
      expect(formatScore(0), '0');
    });

    test('totals including a 10.1 show one decimal', () {
      expect(formatScore(10.1), '10.1');
      expect(formatScore(95.1), '95.1');
      expect(formatScore(10.1 * 3), '30.3');
    });

    test('floating point drift does not leak into the display', () {
      expect(formatScore(10.1 * 10), '101');
      expect(formatScore(0.1 + 0.2 + 9.7), '10');
    });
  });
}
