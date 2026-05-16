// Debounced server-search picker used by the Skills + Languages
// chip pickers. Opens a modal bottom sheet that:
//
//   1. Auto-loads the top N results on first open.
//   2. As the user types, debounces (300ms) and re-queries the server.
//   3. Hides already-selected entries (via `excludeIds`) so the user
//      can't double-add the same skill/language.
//
// Generic over T so call-sites stay type-safe. The caller supplies:
//   • `search(query)` — async fetch
//   • `labelOf(item)` — display text
//   • `idOf(item)`    — identity (used by `excludeIds`)
//   • `subtitleOf(item)?` — optional secondary line (e.g. category)

import 'dart:async';

import 'package:flutter/material.dart';

typedef ChipSearchFn<T>    = Future<List<T>> Function(String query);
typedef ChipLabelOf<T>     = String Function(T item);
typedef ChipIdOf<T>        = int    Function(T item);
typedef ChipSubtitleOf<T>  = String? Function(T item);

/// Open the picker. Returns the chosen item or `null` if dismissed.
Future<T?> showChipPicker<T>({
  required BuildContext       context,
  required String             title,
  required ChipSearchFn<T>    search,
  required ChipLabelOf<T>     labelOf,
  required ChipIdOf<T>        idOf,
  ChipSubtitleOf<T>?          subtitleOf,
  Set<int>                    excludeIds = const {},
  String                      placeholder = 'Search…',
  int                         debounceMs  = 300,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ChipPickerSheet<T>(
      title:        title,
      search:       search,
      labelOf:      labelOf,
      idOf:         idOf,
      subtitleOf:   subtitleOf,
      excludeIds:   excludeIds,
      placeholder:  placeholder,
      debounceMs:   debounceMs,
    ),
  );
}

class _ChipPickerSheet<T> extends StatefulWidget {
  const _ChipPickerSheet({
    required this.title,
    required this.search,
    required this.labelOf,
    required this.idOf,
    required this.subtitleOf,
    required this.excludeIds,
    required this.placeholder,
    required this.debounceMs,
  });

  final String              title;
  final ChipSearchFn<T>     search;
  final ChipLabelOf<T>      labelOf;
  final ChipIdOf<T>         idOf;
  final ChipSubtitleOf<T>?  subtitleOf;
  final Set<int>            excludeIds;
  final String              placeholder;
  final int                 debounceMs;

  @override
  State<_ChipPickerSheet<T>> createState() => _ChipPickerSheetState<T>();
}

class _ChipPickerSheetState<T> extends State<_ChipPickerSheet<T>> {
  final _queryCtl = TextEditingController();
  Timer? _debounce;
  List<T> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: widget.debounceMs), () => _run(q));
  }

  Future<void> _run(String q) async {
    setState(() {
      _loading = true;
      _error   = null;
    });
    try {
      final rows = await widget.search(q);
      if (!mounted) return;
      setState(() => _results = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = _results.where((it) => !widget.excludeIds.contains(widget.idOf(it))).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text(widget.title, style: theme.textTheme.titleLarge)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _queryCtl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _onChanged,
              ),
            ),
            Expanded(child: _body(visible, theme, scrollCtrl)),
          ],
        );
      },
    );
  }

  Widget _body(List<T> visible, ThemeData theme, ScrollController scrollCtrl) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 36, color: theme.colorScheme.error),
              const SizedBox(height: 8),
              Text(_error!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    if (visible.isEmpty && !_loading) {
      return Center(
        child: Text(
          _queryCtl.text.isEmpty
              ? 'Start typing to search.'
              : 'No matches.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      );
    }
    return ListView.builder(
      controller: scrollCtrl,
      itemCount: visible.length,
      itemBuilder: (_, i) {
        final it = visible[i];
        final sub = widget.subtitleOf?.call(it);
        return ListTile(
          dense: true,
          title: Text(widget.labelOf(it)),
          subtitle: (sub ?? '').isEmpty ? null : Text(sub!),
          trailing: const Icon(Icons.add),
          onTap: () => Navigator.of(context).pop(it),
        );
      },
    );
  }
}
