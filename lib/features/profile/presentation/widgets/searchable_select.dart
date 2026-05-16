// Mobile-native searchable picker.
//
// Layout: read-only text field shows the selected label. Tap → modal
// bottom sheet with a search input + scrollable filtered list. The
// caller supplies a list of items + labelOf + onSelected.
//
// Generic over T so call-sites stay type-safe — `SearchableSelect<Country>`,
// `SearchableSelect<MasterLanguage>`, etc.

import 'package:flutter/material.dart';

typedef LabelOf<T>    = String Function(T item);
typedef OnSelected<T> = void Function(T item);

class SearchableSelect<T> extends StatelessWidget {
  const SearchableSelect({
    super.key,
    required this.label,
    required this.items,
    required this.labelOf,
    required this.onSelected,
    this.selectedItem,
    this.placeholder = 'Select…',
    this.enabled = true,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.isLoading = false,
    this.emptyMessage = 'No options available.',
  });

  /// Floating label, e.g. "Country".
  final String label;
  final List<T> items;
  final LabelOf<T> labelOf;
  final OnSelected<T> onSelected;
  /// Currently-selected item (will be matched by `==` against `items`).
  /// Pass `null` for "no selection yet".
  final T? selectedItem;
  final String placeholder;
  final bool   enabled;
  final String? errorText;
  final String? helperText;
  final Widget? prefixIcon;
  /// While loading, the field shows a tiny spinner instead of the chevron
  /// and disables the tap target.
  final bool isLoading;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLabel = selectedItem != null ? labelOf(selectedItem!) : null;
    return InkWell(
      onTap: (enabled && !isLoading) ? () => _openPicker(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          helperText: helperText,
          prefixIcon: prefixIcon,
          enabled: enabled,
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        isEmpty: selectedLabel == null,
        child: Text(
          selectedLabel ?? placeholder,
          style: selectedLabel == null
              ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
              : theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _PickerSheet<T>(
        items:        items,
        labelOf:      labelOf,
        emptyMessage: emptyMessage,
        title:        label,
        selectedItem: selectedItem,
      ),
    );
    if (picked != null) onSelected(picked);
  }
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.items,
    required this.labelOf,
    required this.emptyMessage,
    required this.title,
    required this.selectedItem,
  });

  final List<T> items;
  final LabelOf<T> labelOf;
  final String emptyMessage;
  final String title;
  final T? selectedItem;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  final _queryCtl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items.where((it) => widget.labelOf(it).toLowerCase().contains(q)).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            // Drag handle
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
                  Expanded(
                    child: Text(widget.title, style: theme.textTheme.titleLarge),
                  ),
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
                decoration: const InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.emptyMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final it = filtered[i];
                        final selected = it == widget.selectedItem;
                        return ListTile(
                          dense: true,
                          title: Text(widget.labelOf(it)),
                          trailing: selected ? const Icon(Icons.check) : null,
                          selected: selected,
                          onTap: () => Navigator.of(context).pop(it),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
