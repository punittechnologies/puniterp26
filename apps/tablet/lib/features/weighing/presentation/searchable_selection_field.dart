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
    final displayedValue = value == null ? hint : optionLabel(value as T);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => _openPicker(context) : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              constraints: const BoxConstraints(minHeight: 62),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFFF6F9FE)
                    : const Color(0xFFF1F5F9),
                border: Border.all(
                  color: enabled
                      ? const Color(0xFF9FC5FF)
                      : const Color(0xFFCBD5E1),
                  width: 1.4,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF0B57D0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayedValue,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: value == null
                            ? const Color(0xFF64748B)
                            : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          enabled
              ? 'Tap here to search and select'
              : 'Select the required item first',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF0B57D0),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
