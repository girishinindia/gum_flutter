// Custom in-app filter screen.
//
// Called AFTER `image_cropper` has cropped + rotated + resized the source
// file. Lets the user fine-tune brightness/contrast/saturation via three
// sliders, and pick a preset filter (B&W, Sepia, Cool, Warm, Vivid).
// Final result is encoded as JPEG @ 90% quality and returned via
// `Navigator.pop(context, File)`.
//
// We use the pure-Dart `image` package so the work runs on the Dart
// isolate — no platform channels, no native callbacks, no permissions.
// Performance is fine for the avatar use case (≤ 1024×1024 JPEG after
// the cropper has done its resize step).
//
// Sliders work in [-1, 1] space with the centre as the identity (no
// change). They're rendered as a value/100 percentage label for the user.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

enum ImagePreset { none, mono, sepia, cool, warm, vivid }

class ImageFilterScreen extends StatefulWidget {
  const ImageFilterScreen({
    super.key,
    required this.source,
    this.title = 'Adjust photo',
  });

  /// JPEG/PNG file produced by `image_cropper`. Read once and decoded into
  /// a working `img.Image`; the original file on disk is never modified.
  final File source;
  final String title;

  @override
  State<ImageFilterScreen> createState() => _ImageFilterScreenState();
}

class _ImageFilterScreenState extends State<ImageFilterScreen> {
  img.Image? _baseImage;             // decoded once, never mutated
  Uint8List?  _previewBytes;          // re-encoded each time the slider settles
  bool _processing = false;
  bool _saving     = false;

  // Adjustment values — all default to 0 (identity).
  double _brightness = 0;             // [-1, 1]   → image lib expects [-100, 100]
  double _contrast   = 0;             // [-1, 1]   → image lib accepts a scale around 1
  double _saturation = 0;             // [-1, 1]   → image lib expects [0, 2]
  ImagePreset _preset = ImagePreset.none;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      final bytes = await widget.source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      // Bake the orientation flag — some phones (Pixel, older iPhones)
      // ship a portrait JPEG with an EXIF rotation rather than rotated
      // pixels. If we forget this, the filter preview looks rotated.
      final fixed = img.bakeOrientation(decoded);
      _baseImage = fixed;
      _previewBytes = bytes;
      await _renderPreview();
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// Apply the current sliders + preset to a copy of the base image and
  /// re-encode as JPEG. Cheap enough to do on every slider change for
  /// reasonably-sized avatars.
  Future<void> _renderPreview() async {
    if (_baseImage == null) return;
    setState(() => _processing = true);
    final out = _apply(_baseImage!.clone());
    final bytes = img.encodeJpg(out, quality: 88);
    if (!mounted) return;
    setState(() {
      _previewBytes = Uint8List.fromList(bytes);
      _processing   = false;
    });
  }

  img.Image _apply(img.Image input) {
    var im = input;

    // ── 1) Preset (applied first so sliders fine-tune on top) ─────────
    switch (_preset) {
      case ImagePreset.none: break;
      case ImagePreset.mono:
        im = img.grayscale(im);
      case ImagePreset.sepia:
        im = img.sepia(im, amount: 1.0);
      case ImagePreset.cool:
        im = img.colorOffset(im, red: -10, green: 0, blue: 18);
      case ImagePreset.warm:
        im = img.colorOffset(im, red: 18, green: 4, blue: -10);
      case ImagePreset.vivid:
        im = img.adjustColor(im, saturation: 1.45, contrast: 1.10);
    }

    // ── 2) Slider adjustments — applied in a single pass for speed ────
    final bright = (_brightness * 100).toDouble();          // -100..100
    final contrast = (1.0 + _contrast * 0.6).toDouble();    //  0.4..1.6
    final saturation = (1.0 + _saturation * 1.0).toDouble();//  0..2
    if (bright != 0 || contrast != 1 || saturation != 1) {
      im = img.adjustColor(
        im,
        brightness: bright == 0 ? null : 1.0 + bright / 100.0,
        contrast:   contrast == 1 ? null : contrast,
        saturation: saturation == 1 ? null : saturation,
      );
    }
    return im;
  }

  Future<void> _save() async {
    if (_baseImage == null) return;
    setState(() => _saving = true);
    final out = _apply(_baseImage!.clone());
    final bytes = img.encodeJpg(out, quality: 90);
    // Write to a temp sibling of the source so the upload pipeline gets
    // a real File path (multipart wrapper expects that).
    final temp = File(
      '${widget.source.parent.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await temp.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    Navigator.of(context).pop<File>(temp);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Preview ────────────────────────────────────────────────
          Expanded(
            child: Container(
              alignment: Alignment.center,
              color: Colors.black,
              child: _previewBytes == null
                  ? const CircularProgressIndicator()
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.memory(_previewBytes!, gaplessPlayback: true),
                        if (_processing)
                          const Positioned(
                            top: 12, right: 12,
                            child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // ── Preset strip ───────────────────────────────────────────
          SizedBox(
            height: 56,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _PresetChip(label: 'Original', active: _preset == ImagePreset.none, onTap: () => _pickPreset(ImagePreset.none)),
                _PresetChip(label: 'Mono',     active: _preset == ImagePreset.mono,  onTap: () => _pickPreset(ImagePreset.mono)),
                _PresetChip(label: 'Sepia',    active: _preset == ImagePreset.sepia, onTap: () => _pickPreset(ImagePreset.sepia)),
                _PresetChip(label: 'Cool',     active: _preset == ImagePreset.cool,  onTap: () => _pickPreset(ImagePreset.cool)),
                _PresetChip(label: 'Warm',     active: _preset == ImagePreset.warm,  onTap: () => _pickPreset(ImagePreset.warm)),
                _PresetChip(label: 'Vivid',    active: _preset == ImagePreset.vivid, onTap: () => _pickPreset(ImagePreset.vivid)),
              ],
            ),
          ),

          // ── Sliders ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                _SliderRow(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Brightness',
                  value: _brightness,
                  onChanged: (v) => setState(() => _brightness = v),
                  onChangeEnd: (_) => _renderPreview(),
                  theme: theme,
                ),
                _SliderRow(
                  icon: Icons.tonality,
                  label: 'Contrast',
                  value: _contrast,
                  onChanged: (v) => setState(() => _contrast = v),
                  onChangeEnd: (_) => _renderPreview(),
                  theme: theme,
                ),
                _SliderRow(
                  icon: Icons.opacity,
                  label: 'Saturation',
                  value: _saturation,
                  onChanged: (v) => setState(() => _saturation = v),
                  onChangeEnd: (_) => _renderPreview(),
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickPreset(ImagePreset p) {
    setState(() => _preset = p);
    _renderPreview();
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(width: 86, child: Text(label, style: theme.textTheme.bodyMedium)),
        Expanded(
          child: Slider(
            min: -1, max: 1, value: value,
            onChanged:    onChanged,
            onChangeEnd:  onChangeEnd,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            pct == 0 ? '0' : (pct > 0 ? '+$pct' : '$pct'),
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
