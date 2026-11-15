import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';

enum MascotCharacter { fips, fina }

class MascotBanner extends StatelessWidget {
  final MascotCharacter character;
  final String message;
  final VoidCallback? onTap;

  const MascotBanner({
    super.key,
    required this.character,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFips = character == MascotCharacter.fips;
    final accentColor = isFips ? AppColors.foxOrange : AppColors.owlTeal;
    final name = isFips ? 'Fips' : 'Fina';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: CustomPaint(
                painter: _MascotPainter(character: character),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.volume_up_rounded, color: accentColor, size: 28),
          ],
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotCharacter character;

  _MascotPainter({required this.character});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    if (character == MascotCharacter.fips) {
      // Friendly Fox "Fips"
      final earPaint = Paint()..color = const Color(0xFFE65100);
      final leftEar = Path()
        ..moveTo(cx - r * 0.75, cy - r * 0.3)
        ..lineTo(cx - r * 0.85, cy - r * 1.05)
        ..lineTo(cx - r * 0.2, cy - r * 0.75)
        ..close();
      final rightEar = Path()
        ..moveTo(cx + r * 0.75, cy - r * 0.3)
        ..lineTo(cx + r * 0.85, cy - r * 1.05)
        ..lineTo(cx + r * 0.2, cy - r * 0.75)
        ..close();
      canvas.drawPath(leftEar, earPaint);
      canvas.drawPath(rightEar, earPaint);

      canvas.drawCircle(
        Offset(cx, cy + 2),
        r,
        Paint()..color = AppColors.foxOrange,
      );
      // White cheeks
      final cheekPaint = Paint()..color = Colors.white;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - r * 0.42, cy + r * 0.32),
          width: r * 0.75,
          height: r * 0.55,
        ),
        cheekPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + r * 0.42, cy + r * 0.32),
          width: r * 0.75,
          height: r * 0.55,
        ),
        cheekPaint,
      );
      // Eyes & nose
      final darkPaint = Paint()..color = const Color(0xFF1F2937);
      canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.1), 3.2, darkPaint);
      canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.1), 3.2, darkPaint);
      canvas.drawCircle(Offset(cx, cy + r * 0.32), 4.0, darkPaint);
    } else {
      // Friendly Owl "Fina"
      canvas.drawCircle(
        Offset(cx, cy + 2),
        r,
        Paint()..color = AppColors.owlTeal,
      );
      final earPaint = Paint()..color = const Color(0xFF00695C);
      canvas.drawCircle(Offset(cx - r * 0.65, cy - r * 0.75), r * 0.24, earPaint);
      canvas.drawCircle(Offset(cx + r * 0.65, cy - r * 0.75), r * 0.24, earPaint);

      final eyeBg = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(cx - r * 0.36, cy - r * 0.08), r * 0.32, eyeBg);
      canvas.drawCircle(Offset(cx + r * 0.36, cy - r * 0.08), r * 0.32, eyeBg);

      final pupil = Paint()..color = const Color(0xFF1F2937);
      canvas.drawCircle(Offset(cx - r * 0.34, cy - r * 0.08), 3.5, pupil);
      canvas.drawCircle(Offset(cx + r * 0.34, cy - r * 0.08), 3.5, pupil);

      final beak = Path()
        ..moveTo(cx - 5, cy + r * 0.14)
        ..lineTo(cx + 5, cy + r * 0.14)
        ..lineTo(cx, cy + r * 0.40)
        ..close();
      canvas.drawPath(beak, Paint()..color = AppColors.starGold);
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) {
    return oldDelegate.character != character;
  }
}
