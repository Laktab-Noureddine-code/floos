import 'package:floos/core/l10n/l10n.dart';
import 'package:floos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Numeric PIN entry with dots and a 3×4 keypad.
class PinPad extends StatelessWidget {
  const PinPad({
    required this.length,
    required this.onChanged,
    required this.onSubmit,
    super.key,
    this.pin = '',
    this.maxLength = 6,
    this.minLength = 4,
    this.error,
    this.extra,
  });

  final int length;
  final String pin;
  final int maxLength;
  final int minLength;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final String? error;

  /// Widget in the bottom-left key slot (e.g. biometrics).
  final Widget? extra;

  void _tap(String d) {
    if (pin.length >= maxLength) return;
    HapticFeedback.selectionClick();
    final next = pin + d;
    onChanged(next);
    if (next.length == maxLength) onSubmit(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget key(Widget child, VoidCallback? onTap, {String? label}) => Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: SizedBox(width: 72, height: 64, child: Center(child: child)),
      ),
    );
    Widget digit(String d) => key(Text(d, style: context.text.displayM), () => _tap(d), label: d);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < maxLength; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < pin.length ? c.primary : Colors.transparent,
                  border: Border.all(color: error != null ? c.expense : c.primary, width: 1.5),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 32,
          child: Center(
            child: error == null ? null : Text(error!, style: context.text.caption.copyWith(color: c.expense)),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final d in row) digit(d)]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 72, height: 64, child: Center(child: extra)),
            digit('0'),
            key(
              const Icon(Icons.backspace_outlined),
              pin.isEmpty ? null : () => onChanged(pin.substring(0, pin.length - 1)),
              label: context.l10n.a11yBackspace,
            ),
          ],
        ),
        if (pin.length >= minLength && pin.length < maxLength)
          TextButton(onPressed: () => onSubmit(pin), child: Text(context.l10n.confirm)),
      ],
    );
  }
}

/// Dialog asking the user to create a PIN (enter + confirm). Returns the PIN.
Future<String?> createPinDialog(BuildContext context) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const _CreatePin(),
);

class _CreatePin extends StatefulWidget {
  const _CreatePin();

  @override
  State<_CreatePin> createState() => _CreatePinState();
}

class _CreatePinState extends State<_CreatePin> {
  String _pin = '';
  String? _first;
  String? _error;

  void _submit(String v) {
    final l = context.l10n;
    if (_first == null) {
      setState(() {
        _first = v;
        _pin = '';
        _error = null;
      });
    } else if (_first == v) {
      Navigator.pop(context, v);
    } else {
      setState(() {
        _first = null;
        _pin = '';
        _error = l.errPinMismatch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.x2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_first == null ? l.pinCreate : l.pinConfirm, style: context.text.titleM, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.lg),
          PinPad(length: 6, pin: _pin, error: _error, onChanged: (v) => setState(() => _pin = v), onSubmit: _submit),
        ],
      ),
    );
  }
}
