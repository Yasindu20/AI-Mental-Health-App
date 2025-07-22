// frontend/lib/providers/meditation_provider.dart
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

  // External content properties - ENHANCED with pagination
  List<Meditation> _externalMeditations = [];
  bool _isLoadingExternal = false;
  String _selectedSource = 'all';
  String? _externalError;
  int _currentPage = 1;
  bool _hasNextPage = false;
  int _totalPages = 1;
  int _totalCount = 0;
  final int _perPage = 50; // INCREASED from 20 to 50
  bool _isLoadingMore = false;

  List<Meditation> get externalMeditations => _externalMeditations;
  bool get isLoadingExternal => _isLoadingExternal;
  bool get isLoadingMore => _isLoadingMore;
  String get selectedSource => _selectedSource;
  String? get externalError => _externalError;
  int get currentPage => _currentPage;
  bool get hasNextPage => _hasNextPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  int get perPage => _perPage;

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

  // ENHANCED external content methods with pagination
  Future<void> loadExternalMeditations({
    String source = 'all',
    bool refresh = false,
  }) async {
    if (_isLoadingExternal && !refresh) return;

    _isLoadingExternal = true;
    _externalError = null;

    if (refresh || _selectedSource != source) {
      // Reset pagination for new source or refresh
      _currentPage = 1;
      _externalMeditations = [];
    }

    _selectedSource = source;
    notifyListeners();

    try {
      print(
          'Loading external meditations for source: $source, page: $_currentPage');

      final result = await ApiService.getExternalMeditationsWithPagination(
        source: source,
        page: _currentPage,
        perPage: _perPage,
      );

      if (result.containsKey('error')) {
        _externalError = result['error'];
      } else {
        final meditations = result['meditations'] as List<Meditation>;
        final pagination = result['pagination'] as Map<String, dynamic>;

        if (_currentPage == 1) {
          _externalMeditations = meditations;
        } else {
          _externalMeditations.addAll(meditations);
        }

        _totalCount = pagination['count'] ?? 0;
        _hasNextPage = pagination['has_next'] ?? false;
        _totalPages = pagination['total_pages'] ?? 1;

        print(
            'Loaded ${meditations.length} external meditations, total: $_totalCount');

        if (meditations.isEmpty && _currentPage == 1) {
          _externalError =
              'No content available for this source. The service may be temporarily unavailable.';
        }
      }
    } catch (e) {
      _externalError = 'Failed to load external content: $e';
      print('Error loading external meditations: $e');
      if (_currentPage == 1) {
        _externalMeditations = [];
      }
    } finally {
      _isLoadingExternal = false;
      notifyListeners();
    }
  }

  // Load more content (pagination)
  Future<void> loadMoreExternalMeditations() async {
    if (!_hasNextPage || _isLoadingMore || _isLoadingExternal) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      print('Loading more external meditations, page: ${_currentPage + 1}');

      final result = await ApiService.getExternalMeditationsWithPagination(
        source: _selectedSource,
        page: _currentPage + 1,
        perPage: _perPage,
      );

      if (!result.containsKey('error')) {
        final meditations = result['meditations'] as List<Meditation>;
        final pagination = result['pagination'] as Map<String, dynamic>;

        _externalMeditations.addAll(meditations);
        _currentPage++;
        _hasNextPage = pagination['has_next'] ?? false;

        print(
            'Loaded ${meditations.length} more meditations, total now: ${_externalMeditations.length}');
      }
    } catch (e) {
      print('Error loading more external meditations: $e');
    } finally {
      _isLoadingMore = false;
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
      _currentPage = 1;
      _externalMeditations = [];
      loadExternalMeditations(source: source);
    }
  }

  void clearExternalError() {
    _externalError = null;
    notifyListeners();
  }

  // Get pagination info for UI
  String getPaginationInfo() {
    if (_totalCount == 0) return 'No results';

    final start = (_currentPage - 1) * _perPage + 1;
    final end = (_currentPage * _perPage).clamp(0, _totalCount);

    return 'Showing $start-$end of $_totalCount results (Page $_currentPage of $_totalPages)';
  }

  // Check if we can load more
  bool get canLoadMore =>
      _hasNextPage && !_isLoadingMore && !_isLoadingExternal;
}
