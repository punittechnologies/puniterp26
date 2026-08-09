import 'dart:async';

import 'package:flutter/material.dart';

class SearchableSelectionField<T> extends StatelessWidget {
  const SearchableSelectionField({
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
    this.enabled = true,
    this.allowClear = false,
    super.key,
  });

  final String label;
  final String hint;
  final T? value;
  final List<T> options;
  final String Function(T value) optionLabel;
  final FutureOr<void> Function(T? value) onChanged;
  final bool enabled;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _openPicker(context) : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: enabled
              ? const Color(0xFFF6F9FE)
              : const Color(0xFFF1F5F9),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF9FC5FF), width: 1.4),
          ),
          labelText: label,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF0B57D0),
          ),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          helperText: enabled
              ? 'Tap here to search and select'
              : 'Select the required item first',
          helperStyle: const TextStyle(
            color: Color(0xFF0B57D0),
            fontWeight: FontWeight.w700,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
        isEmpty: value == null,
        child: Text(
          value == null ? hint : optionLabel(value as T),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: value == null ? Colors.black54 : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    var query = '';
    final selected = await showDialog<_SearchSelection<T>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = options
              .where(
                (option) => optionLabel(
                  option,
                ).toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

          return AlertDialog(
            title: Text('Search $label'.replaceAll(' *', '')),
            content: SizedBox(
              width: 520,
              height: 440,
              child: Column(
                children: [
                  TextField(
                    key: const Key('searchable-selection-query'),
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Type to search',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) =>
                        setDialogState(() => query = text.trim()),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No matching options'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final option = filtered[index];
                              final isSelected = option == value;
                              return ListTile(
                                title: Text(optionLabel(option)),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.blue,
                                      )
                                    : null,
                                onTap: () => Navigator.of(
                                  context,
                                ).pop(_SearchSelection.chosen(option)),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              if (allowClear)
                TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_SearchSelection<T>.chosen(null)),
                  child: const Text('Clear'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );

    if (!context.mounted || selected == null || !selected.didChoose) return;
    await onChanged(selected.value);
  }
}

class _SearchSelection<T> {
  const _SearchSelection._(this.value, this.didChoose);

  factory _SearchSelection.chosen(T? value) => _SearchSelection._(value, true);

  final T? value;
  final bool didChoose;
}
