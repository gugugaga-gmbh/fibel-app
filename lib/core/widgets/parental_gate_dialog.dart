import 'dart:math';
import 'package:material_ui/material_ui.dart';

class ParentalGateDialog extends StatefulWidget {
  const ParentalGateDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const ParentalGateDialog(),
    );
    return result ?? false;
  }

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  late final int _a;
  late final int _b;
  final _controller = TextEditingController();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = 12 + rng.nextInt(15);
    _b = 7 + rng.nextInt(12);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == _a + _b) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Elternbereich'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bitte löse diese Aufgabe, um fortzufahren:'),
          const SizedBox(height: 12),
          Text(
            '$_a + $_b = ?',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Antwort',
              errorText: _hasError ? 'Das stimmt noch nicht.' : null,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _verify(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _verify,
          child: const Text('Öffnen'),
        ),
      ],
    );
  }
}
