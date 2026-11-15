import 'dart:ui';

class StrokeValidator {
  /// Checks if the user's drawn points sufficiently cover the normalized
  /// reference strokes within a child-friendly tolerance radius.
  static bool validateStrokes({
    required List<List<Offset>> referenceStrokes,
    required List<List<Offset>> userStrokesNormalized,
    double tolerance = 0.14,
    double minCoverage = 0.70,
  }) {
    if (referenceStrokes.isEmpty || userStrokesNormalized.isEmpty) {
      return false;
    }

    final userPoints = userStrokesNormalized.expand((s) => s).toList();
    if (userPoints.length < 4) return false;

    final sampledRefPoints = <Offset>[];
    for (final stroke in referenceStrokes) {
      for (int i = 0; i < stroke.length; i++) {
        sampledRefPoints.add(stroke[i]);
        if (i + 1 < stroke.length) {
          final start = stroke[i];
          final end = stroke[i + 1];
          const steps = 6;
          for (int s = 1; s < steps; s++) {
            final t = s / steps;
            sampledRefPoints.add(Offset.lerp(start, end, t)!);
          }
        }
      }
    }

    if (sampledRefPoints.isEmpty) return false;

    int coveredCount = 0;
    for (final refPt in sampledRefPoints) {
      final isCovered = userPoints.any(
        (uPt) => (uPt - refPt).distance <= tolerance,
      );
      if (isCovered) coveredCount++;
    }

    final coverage = coveredCount / sampledRefPoints.length;
    return coverage >= minCoverage;
  }
}
