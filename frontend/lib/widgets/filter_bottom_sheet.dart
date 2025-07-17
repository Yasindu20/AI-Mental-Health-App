import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meditation_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({Key? key}) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  List<String> _selectedDurations = [];
  RangeValues _durationRange = const RangeValues(5, 30);

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MeditationProvider>(context, listen: false);
    _selectedCategory = provider.selectedCategory;
    _selectedLevel = provider.selectedLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Meditations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Color(0xFF6B4EFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Section
                  _buildSectionTitle('Category'),
                  _buildCategoryChips(),
                  const SizedBox(height: 24),

                  // Level Section
                  _buildSectionTitle('Experience Level'),
                  _buildLevelChips(),
                  const SizedBox(height: 24),

                  // Duration Section
                  _buildSectionTitle('Duration Range'),
                  _buildDurationSlider(),
                  const SizedBox(height: 24),

                  // Quick Duration Filters
                  _buildSectionTitle('Quick Duration Filters'),
                  _buildDurationChips(),
                  const SizedBox(height: 24),

                  // Target States Section
                  _buildSectionTitle('What are you looking for?'),
                  _buildTargetStateChips(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      'All',
      'Mindfulness',
      'Breathing',
      'Body Scan',
      'Loving Kindness',
      'Visualization',
      'Movement',
      'Sleep',
      'Stress Relief',
      'Anxiety',
      'Depression',
      'Focus'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = _selectedCategory == category;
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = selected ? category : 'All';
            });
          },
          selectedColor: const Color(0xFF6B4EFF).withOpacity(0.2),
          checkmarkColor: const Color(0xFF6B4EFF),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLevelChips() {
    final levels = ['All', 'Beginner', 'Intermediate', 'Advanced'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((level) {
        final isSelected = _selectedLevel == level;
        return FilterChip(
          label: Text(level),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedLevel = selected ? level : 'All';
            });
          },
          selectedColor: const Color(0xFF6B4EFF).withOpacity(0.2),
          checkmarkColor: const Color(0xFF6B4EFF),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDurationSlider() {
    return Column(
      children: [
        RangeSlider(
          values: _durationRange,
          min: 5,
          max: 60,
          divisions: 11,
          labels: RangeLabels(
            '${_durationRange.start.round()} min',
            '${_durationRange.end.round()} min',
          ),
          activeColor: const Color(0xFF6B4EFF),
          inactiveColor: const Color(0xFF6B4EFF).withOpacity(0.3),
          onChanged: (values) {
            setState(() {
              _durationRange = values;
            });
          },
        ),
        Text(
          '${_durationRange.start.round()} - ${_durationRange.end.round()} minutes',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B4EFF),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChips() {
    final durations = [
      '5 min',
      '10 min',
      '15 min',
      '20 min',
      '30 min',
      '45 min'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: durations.map((duration) {
        final isSelected = _selectedDurations.contains(duration);
        return FilterChip(
          label: Text(duration),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDurations.add(duration);
              } else {
                _selectedDurations.remove(duration);
              }
            });
          },
          selectedColor: const Color(0xFF6B4EFF).withOpacity(0.2),
          checkmarkColor: const Color(0xFF6B4EFF),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetStateChips() {
    final targetStates = [
      'Stress Relief',
      'Better Sleep',
      'Focus',
      'Anxiety Relief',
      'Mood Boost',
      'Self-Compassion',
      'Pain Relief',
      'Emotional Balance'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: targetStates.map((state) {
        return ActionChip(
          label: Text(state),
          onPressed: () {
            // Add logic to filter by target state
          },
          backgroundColor: Colors.grey[100],
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedLevel = 'All';
      _selectedDurations.clear();
      _durationRange = const RangeValues(5, 30);
    });
  }

  void _applyFilters() {
    final provider = Provider.of<MeditationProvider>(context, listen: false);
    provider.setCategory(_selectedCategory);
    provider.setLevel(_selectedLevel);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filters applied successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
