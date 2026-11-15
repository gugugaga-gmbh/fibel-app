import 'package:material_ui/material_ui.dart';
import '../curriculum/curriculum_models.dart';
import '../theme/app_theme.dart';

class SyllableTextWidget extends StatelessWidget {
  final List<String> syllables;
  final double fontSize;
  final bool showArcs;
  final bool showVowelCrowns;
  final int? highlightedIndex;
  final ValueChanged<int>? onSyllableTap;

  const SyllableTextWidget({
    super.key,
    required this.syllables,
    this.fontSize = 40,
    this.showArcs = true,
    this.showVowelCrowns = false,
    this.highlightedIndex,
    this.onSyllableTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(syllables.length, (index) {
        final isEven = index % 2 == 0;
        final color =
            isEven ? AppColors.syllableBlue : AppColors.syllableRed;
        final isHighlighted = highlightedIndex == index;
        final hasVowel = SyllableWord.containsVowel(syllables[index]);

        return GestureDetector(
          onTap: onSyllableTap != null ? () => onSyllableTap!(index) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            decoration: isHighlighted
                ? BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showVowelCrowns && hasVowel)
                  Text(
                    '👑',
                    style: TextStyle(fontSize: (fontSize * 0.34).clamp(11, 18)),
                  ),
                Text(
                  syllables[index],
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.1,
                    letterSpacing: 0.5,
                  ),
                ),
                if (showArcs)
                  SizedBox(
                    width: (syllables[index].length * fontSize * 0.58)
                        .clamp(28.0, 180.0),
                    height: fontSize * 0.35,
                    child: CustomPaint(
                      painter: _SyllableArcPainter(
                        color: color,
                        filled: isHighlighted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SyllableArcPainter extends CustomPainter {
  final Color color;
  final bool filled;

  _SyllableArcPainter({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = filled ? 4.5 : 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(3, 2)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 1.15,
        size.width - 3,
        2,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SyllableArcPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.filled != filled;
  }
}
