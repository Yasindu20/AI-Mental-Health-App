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

  // External content pagination state
  final Map<String, List<Meditation>> _externalMeditations = {
    'all': [],
    'youtube': [],
    'spotify': [],
    'huggingface': [],
  };

  final Map<String, int> _currentPages = {
    'all': 1,
    'youtube': 1,
    'spotify': 1,
    'huggingface': 1,
  };

  final Map<String, bool> _hasMoreContent = {
    'all': true,
    'youtube': true,
    'spotify': true,
    'huggingface': true,
  };

  final Map<String, bool> _isLoadingMore = {
    'all': false,
    'youtube': false,
    'spotify': false,
    'huggingface': false,
  };

  bool _isLoadingExternal = false;
  String _selectedSource = 'all';
  String? _externalError;
  static const int _perPage = 20;

  // Public getters
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

  // External content getters
  List<Meditation> get externalMeditations =>
      _externalMeditations[_selectedSource] ?? [];
  bool get isLoadingExternal => _isLoadingExternal;
  bool get isLoadingMoreExternal => _isLoadingMore[_selectedSource] ?? false;
  String get selectedSource => _selectedSource;
  String? get externalError => _externalError;
  bool get hasMoreExternalContent => _hasMoreContent[_selectedSource] ?? false;
  int get currentExternalPage => _currentPages[_selectedSource] ?? 1;

  List<String> get availableSources => [
        'all',
        'youtube',
        'spotify',
        'huggingface',
      ];

  // Public debug getters - FIX FOR THE ERROR
  Map<String, List<Meditation>> get debugExternalMeditations =>
      Map.unmodifiable(_externalMeditations);
  Map<String, int> get debugCurrentPages => Map.unmodifiable(_currentPages);
  Map<String, bool> get debugHasMoreContent =>
      Map.unmodifiable(_hasMoreContent);

  Future<void> loadMeditations() async {
    if (_isLoading) return;

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
      bool matchesCategory = _selectedCategory == 'All' ||
          meditation.type
              .toLowerCase()
              .contains(_selectedCategory.toLowerCase().replaceAll(' ', '_')) ||
          meditation.targetStates.any((state) =>
              state.toLowerCase().contains(_selectedCategory.toLowerCase()));

      bool matchesLevel = _selectedLevel == 'All' ||
          meditation.level.toLowerCase() == _selectedLevel.toLowerCase();

      bool matchesSearch = _searchQuery.isEmpty ||
          meditation.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          meditation.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          meditation.tags.any(
              (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));

      return matchesCategory && matchesLevel && matchesSearch;
    }).toList();

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

  // Enhanced external content loading with pagination
  Future<void> loadExternalMeditations(
      {String source = 'all', bool refresh = false}) async {
    if (_isLoadingExternal && !refresh) return;

    // Reset pagination state if refreshing or switching sources
    if (refresh || _selectedSource != source) {
      _currentPages[source] = 1;
      _hasMoreContent[source] = true;
      _externalMeditations[source] = [];
    }

    _isLoadingExternal = true;
    _externalError = null;
    _selectedSource = source;
    notifyListeners();

    try {
      print(
          'Loading external meditations for source: $source (page ${_currentPages[source]})');

      final response = await ApiService.getExternalMeditations(
        source: source,
        page: _currentPages[source]!,
        perPage: _perPage,
      );

      print('Received ${response.meditations.length} external meditations');

      if (refresh || _currentPages[source] == 1) {
        _externalMeditations[source] = response.meditations;
      } else {
        _externalMeditations[source]!.addAll(response.meditations);
      }

      _hasMoreContent[source] = response.hasMore;

      if (response.meditations.isEmpty && _currentPages[source] == 1) {
        _externalError =
            'No content available for this source. The service may be temporarily unavailable.';
      }
    } catch (e) {
      _externalError = 'Failed to load external content: $e';
      print('Error loading external meditations: $e');

      if (_currentPages[source] == 1) {
        _externalMeditations[source] = [];
      }
    } finally {
      _isLoadingExternal = false;
      notifyListeners();
    }
  }

  // Load more content for infinite scrolling
  Future<void> loadMoreExternalMeditations() async {
    final source = _selectedSource;

    if (_isLoadingMore[source] == true ||
        _hasMoreContent[source] == false ||
        _isLoadingExternal) {
      return;
    }

    _isLoadingMore[source] = true;
    notifyListeners();

    try {
      _currentPages[source] = (_currentPages[source] ?? 1) + 1;

      print(
          'Loading more external meditations for $source (page ${_currentPages[source]})');

      final response = await ApiService.getExternalMeditations(
        source: source,
        page: _currentPages[source]!,
        perPage: _perPage,
      );

      if (response.meditations.isNotEmpty) {
        _externalMeditations[source]!.addAll(response.meditations);
        print(
            'Added ${response.meditations.length} more items. Total: ${_externalMeditations[source]!.length}');
      }

      _hasMoreContent[source] = response.hasMore;
    } catch (e) {
      print('Error loading more external meditations: $e');
      // Revert page increment on error
      _currentPages[source] = (_currentPages[source] ?? 2) - 1;

      // Don't show error for load more failures, just stop loading
      _hasMoreContent[source] = false;
    } finally {
      _isLoadingMore[source] = false;
      notifyListeners();
    }
  }

  Future<void> refreshExternalContent() async {
    try {
      await ApiService.refreshContent();
      await loadExternalMeditations(source: _selectedSource, refresh: true);
    } catch (e) {
      _externalError = 'Failed to refresh content: $e';
      notifyListeners();
    }
  }

  void setSource(String source) {
    if (_selectedSource != source) {
      _selectedSource = source;

      // Load content for new source if not already loaded
      if (_externalMeditations[source]?.isEmpty ?? true) {
        loadExternalMeditations(source: source);
      } else {
        notifyListeners();
      }
    }
  }

  void clearExternalError() {
    _externalError = null;
    notifyListeners();
  }

  // Reset all external content state
  void resetExternalContent() {
    for (String source in availableSources) {
      _externalMeditations[source] = [];
      _currentPages[source] = 1;
      _hasMoreContent[source] = true;
      _isLoadingMore[source] = false;
    }
    _isLoadingExternal = false;
    _externalError = null;
    notifyListeners();
  }

  // Debug helper method
  Map<String, dynamic> getDebugInfo() {
    return {
      'selectedSource': _selectedSource,
      'externalMeditations': _externalMeditations.map(
        (key, value) => MapEntry(key, value.length),
      ),
      'currentPages': Map.from(_currentPages),
      'hasMoreContent': Map.from(_hasMoreContent),
      'isLoadingMore': Map.from(_isLoadingMore),
      'isLoadingExternal': _isLoadingExternal,
      'externalError': _externalError,
    };
  }
}
