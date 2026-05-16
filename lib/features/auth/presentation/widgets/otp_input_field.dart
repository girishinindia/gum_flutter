// 6-digit OTP input. Single TextField under the hood, with custom
// painted "boxes" overlaid so the UI looks like a row of cells while
// still respecting native keyboard / paste / autofill behaviour.
//
// Why a single TextField (vs. one per box)?
//   • Paste of "123456" works in a single shot — no per-cell juggling.
//   • iOS / Android keyboard "from messages" autofill works.
//   • Cursor / selection behave normally — backspace-into-prev-box etc.
//   • Half the rebuild cost of six controllers.
//
// The boxes are pure decoration drawn over a Container holding the
// TextField; we measure box positions, paint the digit at each index
// from the value, and dim trailing empty slots.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef OtpCompleted = void Function(String otp);

class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.length,
    required this.onChanged,
    this.onCompleted,
    this.error,
    this.autofocus = true,
    this.enabled = true,
    this.focusNode,
  });

  final int           length;
  final ValueChanged<String> onChanged;
  final OtpCompleted? onCompleted;
  final String?       error;
  final bool          autofocus;
  final bool          enabled;
  /// Optional external FocusNode. Pass one when the parent needs to
  /// drive focus (e.g. inside a TabBarView). When null, the widget
  /// owns its own internal node.
  final FocusNode?    focusNode;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  final _controller = TextEditingController();
  FocusNode get _focus => widget.focusNode ?? _internalFocus;
  final FocusNode _internalFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  void _onChange() {
    final raw = _controller.text;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final clamped = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    if (clamped != raw) {
      _controller.value = TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
      return; // listener will re-fire with the cleaned value
    }
    widget.onChanged(clamped);
    if (clamped.length == widget.length) {
      widget.onCompleted?.call(clamped);
    }
    setState(() {}); // repaint boxes
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _controller.dispose();
    // Only dispose the focus node we own.
    _internalFocus.dispose();
    super.dispose();
  }

  void clear() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boxSize = 46.0;
    final gap     = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Stack(
            children: [
              // Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    _Box(
                      char:    i < _controller.text.length ? _controller.text[i] : '',
                      focused: _focus.hasFocus && i == _controller.text.length,
                      error:   widget.error != null,
                      size:    boxSize,
                    ),
                    if (i < widget.length - 1) SizedBox(width: gap),
                  ],
                ],
              ),
              // Invisible TextField that owns the input.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller:      _controller,
                    focusNode:       _focus,
                    autofocus:       widget.autofocus,
                    enabled:         widget.enabled,
                    keyboardType:    TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    autofillHints: const [AutofillHints.oneTimeCode],
                    showCursor: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.error!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.char, required this.focused, required this.error, required this.size});

  final String  char;
  final bool    focused;
  final bool    error;
  final double  size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color borderColor;
    if (error) {
      borderColor = theme.colorScheme.error;
    } else if (focused) {
      borderColor = theme.colorScheme.primary;
    } else if (char.isNotEmpty) {
      borderColor = theme.colorScheme.primary.withValues(alpha: 0.5);
    } else {
      borderColor = theme.dividerColor;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: focused ? 2 : 1.2),
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surface,
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
