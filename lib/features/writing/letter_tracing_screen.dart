import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service.dart';
import '../../core/curriculum/curriculum_models.dart';
import '../../core/storage/progress_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/mascot_widget.dart';
import 'stroke_validator.dart';

enum _TracingMode {
  upper('upper'),
  lower('lower'),
  freehand('freehand');

  final String stepKey;
  const _TracingMode(this.stepKey);
}

class LetterTracingScreen extends ConsumerStatefulWidget {
  final LessonUnit unit;

  const LetterTracingScreen({super.key, required this.unit});

  @override
  ConsumerState<LetterTracingScreen> createState() =>
      _LetterTracingScreenState();
}

class _LetterTracingScreenState extends ConsumerState<LetterTracingScreen>
    with SingleTickerProviderStateMixin {
  _TracingMode _mode = _TracingMode.upper;
  final List<List<Offset>> _userStrokes = [];
  List<Offset> _currentStroke = [];
  bool _currentStepPassed = false;
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

  List<List<Offset>> get _activeStrokes => switch (_mode) {
        _TracingMode.upper => widget.unit.upperStrokes,
        _TracingMode.lower => widget.unit.lowerStrokes,
        _TracingMode.freehand => widget.unit.upperStrokes,
      };

  void _clearCanvas() {
    setState(() {
      _userStrokes.clear();
      _currentStroke = [];
      _currentStepPassed = false;
      _feedback = null;
    });
  }

  void _advanceToNextPendingStep(ChildProgress progress) {
    final unitId = widget.unit.id;
    if (!progress.isTracingStepCompleted(unitId, 'upper')) {
      setState(() {
        _mode = _TracingMode.upper;
        _clearCanvas();
      });
    } else if (!progress.isTracingStepCompleted(unitId, 'lower')) {
      setState(() {
        _mode = _TracingMode.lower;
        _clearCanvas();
      });
    } else if (!progress.isTracingStepCompleted(unitId, 'freehand')) {
      setState(() {
        _mode = _TracingMode.freehand;
        _clearCanvas();
      });
    }
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
      tolerance: _mode == _TracingMode.freehand ? 0.17 : 0.14,
      minCoverage: _mode == _TracingMode.freehand ? 0.65 : 0.70,
    );

    if (ok) {
      final allDone = await ref
          .read(progressProvider.notifier)
          .recordTracingStep(widget.unit.id, _mode.stepKey);

      setState(() {
        _currentStepPassed = true;
        _feedback = allDone
            ? 'Alle 3 Schreib-Aufgaben geschafft! ⭐'
            : 'Super geschrieben! Weiter zum nächsten Schritt!';
      });

      await ref.read(audioServiceProvider).speakWord(
            allDone
                ? 'Klasse! Du hast Groß, Klein und Frei geschrieben!'
                : 'Toll gemacht! Weiter zum nächsten Schritt.',
          );
    } else {
      setState(() {
        _feedback = _mode == _TracingMode.freehand
            ? 'Schreibe das „${widget.unit.letter}“ vom grünen Punkt aus ins Linienhaus!'
            : 'Spure die Linien noch etwas genauer nach!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final unitId = widget.unit.id;
    final upperDone = progress.isTracingStepCompleted(unitId, 'upper');
    final lowerDone = progress.isTracingStepCompleted(unitId, 'lower');
    final freeDone = progress.isTracingStepCompleted(unitId, 'freehand');
    final moduleCompleted =
        progress.isModuleCompleted(unitId, ModuleType.tracing);

    final targetChar = switch (_mode) {
      _TracingMode.upper => widget.unit.letter,
      _TracingMode.lower => widget.unit.lowercase,
      _TracingMode.freehand => widget.unit.letter,
    };

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Schreiben: ${widget.unit.letter} ${widget.unit.lowercase}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            MascotBanner(
              character: MascotCharacter.fips,
              message: _mode == _TracingMode.freehand
                  ? 'Frei schreiben: Schreibe das „$targetChar“ ohne Hilfslinie! Starte am grünen Punkt.'
                  : 'Spure das „$targetChar“ im Linienhaus nach! Folge den Pfeilen ab Punkt 1.',
              onTap: () => ref
                  .read(audioServiceProvider)
                  .speakPhoneme(widget.unit.phoneme),
            ),
            const SizedBox(height: 10),
            SegmentedButton<_TracingMode>(
              segments: [
                ButtonSegment(
                  value: _TracingMode.upper,
                  label: Text('Groß: ${widget.unit.letter}'),
                  icon: upperDone
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.successGreen, size: 18)
                      : null,
                ),
                ButtonSegment(
                  value: _TracingMode.lower,
                  label: Text('Klein: ${widget.unit.lowercase}'),
                  icon: lowerDone
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.successGreen, size: 18)
                      : null,
                ),
                ButtonSegment(
                  value: _TracingMode.freehand,
                  label: const Text('Frei ✍️'),
                  icon: freeDone
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.successGreen, size: 18)
                      : null,
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (sel) {
                setState(() {
                  _mode = sel.first;
                  _clearCanvas();
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepBadge(label: '1. Groß', done: upperDone),
                const SizedBox(width: 8),
                _StepBadge(label: '2. Klein', done: lowerDone),
                const SizedBox(width: 8),
                _StepBadge(label: '3. Frei', done: freeDone),
              ],
            ),
            const SizedBox(height: 10),
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
                                showGuidePath: _mode != _TracingMode.freehand,
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
            const SizedBox(height: 10),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _feedback!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _currentStepPassed
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
                if (_currentStepPassed && !moduleCompleted) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _advanceToNextPendingStep(ref.read(progressProvider)),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Nächster Schritt'),
                    ),
                  ),
                ] else if (moduleCompleted) ...[
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

class _StepBadge extends StatelessWidget {
  final String label;
  final bool done;

  const _StepBadge({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: done
            ? AppColors.successGreen.withValues(alpha: 0.14)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? AppColors.successGreen : const Color(0xFFD1D5DB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 15,
            color: done ? AppColors.successGreen : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: done ? AppColors.successGreen : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _TracingCanvasPainter extends CustomPainter {
  final List<List<Offset>> referenceStrokes;
  final List<List<Offset>> userStrokes;
  final double pulseValue;
  final Color strokeColor;
  final bool showGuidePath;

  _TracingCanvasPainter({
    required this.referenceStrokes,
    required this.userStrokes,
    required this.pulseValue,
    required this.strokeColor,
    required this.showGuidePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawLineHouse(canvas, size);
    _drawReferenceStrokes(canvas, size);
    _drawUserStrokes(canvas);
  }

  void _drawLineHouse(Canvas canvas, Size size) {
    final roofY = size.height * 0.12;
    final midTopY = size.height * 0.35;
    final baseY = size.height * 0.65;
    final cellarY = size.height * 0.90;

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

      final first = Offset(
        stroke.first.dx * size.width,
        stroke.first.dy * size.height,
      );

      if (showGuidePath) {
        final path = Path()..moveTo(first.dx, first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(
            stroke[i].dx * size.width,
            stroke[i].dy * size.height,
          );
        }
        canvas.drawPath(path, guidePaint);
        canvas.drawPath(path, centerDashPaint);

        if (stroke.length >= 2) {
          final p1 = first;
          final p2 = Offset(
            stroke[1].dx * size.width,
            stroke[1].dy * size.height,
          );
          final mid = Offset.lerp(p1, p2, 0.55)!;
          final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
          _drawDirectionArrow(canvas, mid, angle);
        }
      }

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

  void _drawDirectionArrow(Canvas canvas, Offset tip, double angle) {
    const arrowSize = 7.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowSize * math.cos(angle - 0.55),
        tip.dy - arrowSize * math.sin(angle - 0.55),
      )
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowSize * math.cos(angle + 0.55),
        tip.dy - arrowSize * math.sin(angle + 0.55),
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
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
