// "Resend OTP in 0:42 / Resend OTP" countdown button.
//
// Owns a Timer that ticks every second; when seconds reach 0, the
// button becomes tappable and labelled "Resend OTP". On tap, the
// parent's `onResend` runs (typically a server call) and returns the
// new cooldown duration in seconds — the timer then restarts.

import 'dart:async';

import 'package:flutter/foundation.dart';  // ValueListenable
import 'package:flutter/material.dart';

typedef ResendCallback = Future<int> Function();

class ResendTimer extends StatefulWidget {
  const ResendTimer({
    super.key,
    required this.initialSeconds,
    required this.onResend,
    this.disabledWhile,
  });

  final int             initialSeconds;
  final ResendCallback  onResend;
  /// Pass a `ValueListenable<bool>` to disable the button externally
  /// (e.g. while the parent is busy submitting an OTP). Optional.
  final ValueListenable<bool>? disabledWhile;

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> {
  Timer? _ticker;
  int    _remaining = 0;
  bool   _busy      = false;

  @override
  void initState() {
    super.initState();
    _restart(widget.initialSeconds);
  }

  void _restart(int seconds) {
    _ticker?.cancel();
    setState(() => _remaining = seconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remaining <= 0) {
          t.cancel();
        } else {
          _remaining--;
        }
      });
    });
  }

  Future<void> _onTap() async {
    if (_remaining > 0 || _busy) return;
    setState(() => _busy = true);
    try {
      final next = await widget.onResend();
      if (!mounted) return;
      _restart(next > 0 ? next : 30);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _format(int s) {
    final m  = (s ~/ 60).toString();
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _remaining == 0 && !_busy;
    final extDisabled = widget.disabledWhile;
    return ValueListenableBuilder<bool>(
      valueListenable: extDisabled ?? const _AlwaysFalse(),
      builder: (_, ext, __) {
        final enabled = active && !ext;
        return TextButton(
          onPressed: enabled ? _onTap : null,
          child: _busy
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _remaining > 0
                      ? 'Resend OTP in ${_format(_remaining)}'
                      : 'Resend OTP',
                  style: TextStyle(
                    color: enabled
                        ? theme.colorScheme.primary
                        : theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        );
      },
    );
  }
}

class _AlwaysFalse extends ValueListenable<bool> {
  const _AlwaysFalse();
  @override bool get value => false;
  @override void addListener(VoidCallback _) {}
  @override void removeListener(VoidCallback _) {}
}
