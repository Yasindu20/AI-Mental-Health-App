import 'package:flutter/material.dart';
import '../models/meditation_models.dart';
import '../services/meditation_service.dart';

class MeditationProvider extends ChangeNotifier {
  List<Meditation> _meditations = [];
  List<Meditation> _filteredMeditations = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  String _searchQuery = '';
  UserMeditationStats? _stats;

  List<Meditation> get meditations => _filteredMeditations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get selectedLevel => _selectedLevel;
  String get searchQuery => _searchQuery;
  UserMeditationStats? get stats => _stats;

  List<String> get categories => [
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
        'Focus',
      ];

  List<String> get levels => ['All', 'Beginner', 'Intermediate', 'Advanced'];

  Future<void> loadMeditations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _meditations = await MeditationService.browseMeditations();
      _applyFilters();
    } catch (e) {
      _error = 'Failed to load meditations: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await MeditationService.getUserStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load stats: $e');
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setLevel(String level) {
    _selectedLevel = level;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredMeditations = _meditations.where((meditation) {
      // Category filter
      bool matchesCategory = _selectedCategory == 'All' ||
          meditation.type
              .toLowerCase()
              .contains(_selectedCategory.toLowerCase()) ||
          meditation.targetStates.any((state) =>
              state.toLowerCase().contains(_selectedCategory.toLowerCase()));

      // Level filter
      bool matchesLevel = _selectedLevel == 'All' ||
          meditation.level.toLowerCase() == _selectedLevel.toLowerCase();

      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          meditation.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          meditation.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          meditation.tags.any(
              (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));

      return matchesCategory && matchesLevel && matchesSearch;
    }).toList();

    // Sort by effectiveness and popularity
    _filteredMeditations.sort((a, b) {
      final scoreA = a.effectivenessScore * 0.7 + (a.effectivenessScore * 0.3);
      final scoreB = b.effectivenessScore * 0.7 + (b.effectivenessScore * 0.3);
      return scoreB.compareTo(scoreA);
    });

    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'All';
    _selectedLevel = 'All';
    _searchQuery = '';
    _applyFilters();
  }
}
