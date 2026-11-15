import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import 'stroke_validator.dart';

class LetterTracingScreen extends ConsumerStatefulWidget {
  final LessonUnit unit;

  const LetterTracingScreen({super.key, required this.unit});

  @override
  ConsumerState<LetterTracingScreen> createState() =>
      _LetterTracingScreenState();
}

class _LetterTracingScreenState extends ConsumerState<LetterTracingScreen>
    with SingleTickerProviderStateMixin {
  bool _isUppercase = true;
  final List<List<Offset>> _userStrokes = [];
  List<Offset> _currentStroke = [];
  bool _isCompleted = false;
  String? _feedback;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<List<Offset>> get _activeStrokes =>
      _isUppercase ? widget.unit.upperStrokes : widget.unit.lowerStrokes;

  void _clearCanvas() {
    setState(() {
      _userStrokes.clear();
      _currentStroke = [];
      _isCompleted = false;
      _feedback = null;
    });
  }

  Future<void> _validate(Size canvasSize) async {
    final normalized = _userStrokes
        .map(
          (stroke) => stroke
              .map(
                (pt) => Offset(
                  (pt.dx / canvasSize.width).clamp(0.0, 1.0),
                  (pt.dy / canvasSize.height).clamp(0.0, 1.0),
                ),
              )
              .toList(),
        )
        .toList();

    final ok = StrokeValidator.validateStrokes(
      referenceStrokes: _activeStrokes,
      userStrokesNormalized: normalized,
    );

    if (ok) {
      setState(() {
        _isCompleted = true;
        _feedback = 'Super geschrieben! ⭐';
      });
      await ref
          .read(audioServiceProvider)
          .speakWord('Klasse! Das ist ein tolles ${widget.unit.letter}!');
      await ref
          .read(progressProvider.notifier)
          .completeModule(widget.unit.id, ModuleType.tracing);
    } else {
      setState(() {
        _feedback = 'Spure die Linien noch etwas genauer nach!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetChar =
        _isUppercase ? widget.unit.letter : widget.unit.lowercase;

    return Scaffold(
      appBar: AppBar(
        title: Text('Schreiben: ${widget.unit.letter} ${widget.unit.lowercase}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            MascotBanner(
              character: MascotCharacter.fips,
              message:
                  'Spure das „$targetChar“ im Linienhaus nach! Starte am grünen Punkt.',
              onTap: () => ref
                  .read(audioServiceProvider)
                  .speakPhoneme(widget.unit.phoneme),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text('Groß: ${widget.unit.letter}'),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Klein: ${widget.unit.lowercase}'),
                ),
              ],
              selected: {_isUppercase},
              onSelectionChanged: (sel) {
                setState(() {
                  _isUppercase = sel.first;
                  _clearCanvas();
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _currentStroke = [details.localPosition];
                            _userStrokes.add(_currentStroke);
                            _feedback = null;
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _currentStroke.add(details.localPosition);
                          });
                        },
                        onPanEnd: (_) => _validate(canvasSize),
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return CustomPaint(
                              size: canvasSize,
                              painter: _TracingCanvasPainter(
                                referenceStrokes: _activeStrokes,
                                userStrokes: _userStrokes,
                                pulseValue: _pulseController.value,
                                strokeColor: widget.unit.color,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _feedback!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isCompleted
                        ? AppColors.successGreen
                        : AppColors.foxOrange,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearCanvas,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Neu versuchen'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 52),
                    ),
                  ),
                ),
                if (_isCompleted) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Fertig!'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TracingCanvasPainter extends CustomPainter {
  final List<List<Offset>> referenceStrokes;
  final List<List<Offset>> userStrokes;
  final double pulseValue;
  final Color strokeColor;

  _TracingCanvasPainter({
    required this.referenceStrokes,
    required this.userStrokes,
    required this.pulseValue,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawLineHouse(canvas, size);
    _drawReferenceStrokes(canvas, size);
    _drawUserStrokes(canvas);
  }

  void _drawLineHouse(Canvas canvas, Size size) {
    // 3-line house system: Dach (0.12), Wohnung (0.35 - 0.65), Keller (0.90)
    final roofY = size.height * 0.12;
    final midTopY = size.height * 0.35;
    final baseY = size.height * 0.65;
    final cellarY = size.height * 0.90;

    // Subtle colored bands
    canvas.drawRect(
      Rect.fromLTRB(0, roofY, size.width, midTopY),
      Paint()..color = AppColors.lineHouseRoof.withValues(alpha: 0.08),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, midTopY, size.width, baseY),
      Paint()..color = AppColors.lineHouseMain.withValues(alpha: 0.10),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, baseY, size.width, cellarY),
      Paint()..color = AppColors.lineHouseCellar.withValues(alpha: 0.08),
    );

    final linePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 1.8;

    for (final y in [roofY, midTopY, baseY, cellarY]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Small house labels on the left
    final labels = [
      ('Dach', (roofY + midTopY) / 2 - 7),
      ('Wohnung', (midTopY + baseY) / 2 - 7),
      ('Keller', (baseY + cellarY) / 2 - 7),
    ];
    for (final (text, y) in labels) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF78909C),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(8, y));
    }
  }

  void _drawReferenceStrokes(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerDashPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int s = 0; s < referenceStrokes.length; s++) {
      final stroke = referenceStrokes[s];
      if (stroke.isEmpty) continue;

      final path = Path();
      final first = Offset(
        stroke.first.dx * size.width,
        stroke.first.dy * size.height,
      );
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(
          stroke[i].dx * size.width,
          stroke[i].dy * size.height,
        );
      }

      canvas.drawPath(path, guidePaint);
      canvas.drawPath(path, centerDashPaint);

      // Start dot (pulsing green for first stroke)
      final dotRadius = s == 0 ? 10.0 + pulseValue * 4.0 : 8.0;
      canvas.drawCircle(
        first,
        dotRadius,
        Paint()
          ..color = s == 0 ? AppColors.successGreen : AppColors.syllableBlue,
      );

      final numPainter = TextPainter(
        text: TextSpan(
          text: '${s + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      numPainter.paint(
        canvas,
        first - Offset(numPainter.width / 2, numPainter.height / 2),
      );
    }
  }

  void _drawUserStrokes(Canvas canvas) {
    final userPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in userStrokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, userPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TracingCanvasPainter oldDelegate) => true;
}
