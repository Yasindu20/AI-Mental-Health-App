import 'package:flutter/material.dart';

class SourceFilterChips extends StatelessWidget {
  final List<String> sources;
  final String selectedSource;
  final Function(String) onSourceSelected;

  const SourceFilterChips({
    super.key,
    required this.sources,
    required this.selectedSource,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sources.map((source) {
        final isSelected = selectedSource == source;
        return FilterChip(
          label: Text(_getSourceLabel(source)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onSourceSelected(source);
            }
          },
          selectedColor: const Color(0xFF6B4EFF).withOpacity(0.2),
          checkmarkColor: const Color(0xFF6B4EFF),
          avatar: _getSourceIcon(source),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'all':
        return 'All Sources';
      case 'youtube':
        return 'YouTube';
      case 'spotify':
        return 'Spotify';
      case 'huggingface':
        return 'AI Generated';
      default:
        return source.toUpperCase();
    }
  }

  Widget? _getSourceIcon(String source) {
    IconData? iconData;
    Color? iconColor;

    switch (source) {
      case 'youtube':
        iconData = Icons.play_circle;
        iconColor = Colors.red;
        break;
      case 'spotify':
        iconData = Icons.library_music;
        iconColor = Colors.green;
        break;
      case 'huggingface':
        iconData = Icons.smart_toy;
        iconColor = Colors.orange;
        break;
      case 'all':
        iconData = Icons.all_inclusive;
        iconColor = Colors.blue;
        break;
    }

    if (iconData != null) {
      return Icon(iconData, size: 18, color: iconColor);
    }
    return null;
  }
}
