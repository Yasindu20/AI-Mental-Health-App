import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
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

  List<Meditation> _externalMeditations = [];
  bool _isLoadingExternal = false;
  String _selectedSource = 'all';

  List<Meditation> get externalMeditations => _externalMeditations;
  bool get isLoadingExternal => _isLoadingExternal;
  String get selectedSource => _selectedSource;

  List<String> get availableSources => [
        'all',
        'youtube',
        'spotify',
        'huggingface',
      ];

  Future<void> loadMeditations() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _meditations = await MeditationService.browseMeditations();
      _applyFilters();
      print('Loaded ${_meditations.length} meditations');
    } catch (e) {
      _error = e.toString();
      print('Error loading meditations: $e');

      // If it's an auth error, provide specific message
      if (e.toString().contains('Authentication')) {
        _error = 'Please login to view meditations';
      } else if (e.toString().contains('401')) {
        _error = 'Session expired. Please login again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await MeditationService.getUserStats();
      notifyListeners();
      print('Stats loaded: ${_stats?.totalSessions} sessions');
    } catch (e) {
      print('Failed to load stats: $e');
      // Set default stats instead of failing
      _stats = UserMeditationStats.defaultStats();
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _applyFilters();
    }
  }

  void setLevel(String level) {
    if (_selectedLevel != level) {
      _selectedLevel = level;
      _applyFilters();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
    }
  }

  void _applyFilters() {
    _filteredMeditations = _meditations.where((meditation) {
      // Category filter
      bool matchesCategory = _selectedCategory == 'All' ||
          meditation.type
              .toLowerCase()
              .contains(_selectedCategory.toLowerCase().replaceAll(' ', '_')) ||
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
      final scoreA = a.effectivenessScore;
      final scoreB = b.effectivenessScore;
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> retry() async {
    clearError();
    await loadMeditations();
  }

  Future<void> loadExternalMeditations({String source = 'all'}) async {
    _isLoadingExternal = true;
    _error = null;
    notifyListeners();

    try {
      _externalMeditations =
          await ApiService.getExternalMeditations(source: source);
      _selectedSource = source;
      print('Loaded ${_externalMeditations.length} external meditations');
    } catch (e) {
      _error = e.toString();
      print('Error loading external meditations: $e');
    } finally {
      _isLoadingExternal = false;
      notifyListeners();
    }
  }

  Future<void> refreshContent() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService.refreshContent();
      print('Content refresh result: $result');

      // Reload both regular and external meditations
      await Future.wait([
        loadMeditations(),
        loadExternalMeditations(source: _selectedSource),
      ]);
    } catch (e) {
      _error = e.toString();
      print('Error refreshing content: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSource(String source) {
    if (_selectedSource != source) {
      _selectedSource = source;
      loadExternalMeditations(source: source);
    }
  }
}
