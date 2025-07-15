// frontend/lib/screens/meditation_library_screen.dart
import 'package:flutter/material.dart';
import '../models/meditation_models.dart';
import '../services/meditation_service.dart';
import 'meditation_detail_screen.dart';

class MeditationLibraryScreen extends StatefulWidget {
  const MeditationLibraryScreen({Key? key}) : super(key: key);

  @override
  State<MeditationLibraryScreen> createState() =>
      _MeditationLibraryScreenState();
}

class _MeditationLibraryScreenState extends State<MeditationLibraryScreen> {
  List<Meditation> _meditations = [];
  bool _isLoading = true;
  String? _selectedType;
  String? _selectedLevel;
  String? _selectedState;

  final List<String> _types = [
    'breathing',
    'mindfulness',
    'body_scan',
    'loving_kindness',
    'visualization',
    'movement',
    'mantra',
    'zen'
  ];

  final List<String> _levels = ['beginner', 'intermediate', 'advanced'];

  final List<String> _states = [
    'anxiety',
    'depression',
    'stress',
    'anger',
    'insomnia',
    'focus'
  ];

  @override
  void initState() {
    super.initState();
    _loadMeditations();
  }

  Future<void> _loadMeditations() async {
    setState(() => _isLoading = true);
    try {
      final meditations = await MeditationService.browseMeditations(
        type: _selectedType,
        level: _selectedLevel,
        targetState: _selectedState,
      );
      setState(() {
        _meditations = meditations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load meditations: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation Library'),
        backgroundColor: const Color(0xFF6B4EFF),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Type filter
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All Types', null, _selectedType,
                          (val) => _selectedType = val),
                      ..._types.map((type) => _buildFilterChip(
                            _formatType(type),
                            type,
                            _selectedType,
                            (val) => _selectedType = val,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Level filter
                Row(
                  children: [
                    _buildFilterChip('All Levels', null, _selectedLevel,
                        (val) => _selectedLevel = val),
                    ..._levels.map((level) => _buildFilterChip(
                          _formatLevel(level),
                          level,
                          _selectedLevel,
                          (val) => _selectedLevel = val,
                        )),
                  ],
                ),
              ],
            ),
          ),

          // Meditation list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _meditations.length,
                    itemBuilder: (context, index) {
                      final meditation = _meditations[index];
                      return _buildMeditationCard(meditation);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, String? groupValue,
      Function(String?) onSelected) {
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            onSelected(selected ? value : null);
            _loadMeditations();
          });
        },
        selectedColor: const Color(0xFF6B4EFF).withOpacity(0.2),
        checkmarkColor: const Color(0xFF6B4EFF),
      ),
    );
  }

  Widget _buildMeditationCard(Meditation meditation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MeditationDetailScreen(
                meditation: meditation,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getTypeColor(meditation.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(meditation.type),
                  color: _getTypeColor(meditation.type),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(_formatLevel(meditation.level),
                            _getLevelColor(meditation.level)),
                        const SizedBox(width: 8),
                        _buildTag(
                            '${meditation.durationMinutes} min', Colors.grey),
                        const SizedBox(width: 8),
                        if (meditation.effectivenessScore >= 0.8)
                          _buildTag('Highly Rated', Colors.green),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meditation.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatType(String type) {
    return type.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatLevel(String level) {
    return level[0].toUpperCase() + level.substring(1);
  }

  Color _getTypeColor(String type) {
    final colors = {
      'breathing': Colors.blue,
      'mindfulness': Colors.purple,
      'body_scan': Colors.orange,
      'loving_kindness': Colors.pink,
      'visualization': Colors.teal,
      'movement': Colors.green,
      'mantra': Colors.indigo,
      'zen': Colors.deepPurple,
    };
    return colors[type] ?? Colors.grey;
  }

  IconData _getTypeIcon(String type) {
    final icons = {
      'breathing': Icons.air,
      'mindfulness': Icons.psychology,
      'body_scan': Icons.accessibility_new,
      'loving_kindness': Icons.favorite,
      'visualization': Icons.landscape,
      'movement': Icons.directions_walk,
      'mantra': Icons.music_note,
      'zen': Icons.spa,
    };
    return icons[type] ?? Icons.self_improvement;
  }

  Color _getLevelColor(String level) {
    final colors = {
      'beginner': Colors.green,
      'intermediate': Colors.orange,
      'advanced': Colors.red,
    };
    return colors[level] ?? Colors.grey;
  }
}
