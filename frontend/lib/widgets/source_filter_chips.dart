import 'package:flutter/material.dart';

class SourceFilterChips extends StatelessWidget {
  final List<String> sources;
  final String selectedSource;
  final Function(String) onSourceSelected;

  const SourceFilterChips({
    Key? key,
    required this.sources,
    required this.selectedSource,
    required this.onSourceSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sources.asMap().entries.map((entry) {
          final index = entry.key;
          final source = entry.value;
          final isSelected = selectedSource == source;

          return Padding(
            padding: EdgeInsets.only(
              right: index < sources.length - 1 ? 8 : 0,
            ),
            child: FilterChip(
              label: Text(_getSourceLabel(source)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSourceSelected(source);
                }
              },
              selectedColor: _getSourceColor(source).withOpacity(0.2),
              checkmarkColor: _getSourceColor(source),
              avatar: _getSourceIcon(source),
              labelStyle: TextStyle(
                color: isSelected ? _getSourceColor(source) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? _getSourceColor(source).withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
              ),
              elevation: isSelected ? 2 : 0,
              pressElevation: 4,
            ),
          );
        }).toList(),
      ),
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

  Color _getSourceColor(String source) {
    switch (source) {
      case 'youtube':
        return Colors.red;
      case 'spotify':
        return Colors.green;
      case 'huggingface':
        return Colors.orange;
      case 'all':
        return const Color(0xFF6B4EFF);
      default:
        return Colors.blue;
    }
  }

  Widget? _getSourceIcon(String source) {
    IconData? iconData;
    Color? iconColor = _getSourceColor(source);

    switch (source) {
      case 'youtube':
        iconData = Icons.play_circle;
        break;
      case 'spotify':
        iconData = Icons.library_music;
        break;
      case 'huggingface':
        iconData = Icons.smart_toy;
        break;
      case 'all':
        iconData = Icons.all_inclusive;
        break;
    }

    if (iconData != null) {
      return Icon(iconData, size: 18, color: iconColor);
    }
    return null;
  }
}
