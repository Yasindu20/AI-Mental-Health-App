// frontend/lib/screens/external_content_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/widgets/external_meditation_card.dart';
import 'package:provider/provider.dart';
import '../providers/meditation_provider.dart';
import '../widgets/source_filter_chips.dart';

class ExternalContentScreen extends StatefulWidget {
  const ExternalContentScreen({Key? key}) : super(key: key);

  @override
  State<ExternalContentScreen> createState() => _ExternalContentScreenState();
}

class _ExternalContentScreenState extends State<ExternalContentScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MeditationProvider>(context, listen: false);
      provider.loadExternalMeditations();
    });

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is near the bottom
      final provider = Provider.of<MeditationProvider>(context, listen: false);
      if (provider.canLoadMore) {
        provider.loadMoreExternalMeditations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover More Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final provider =
                  Provider.of<MeditationProvider>(context, listen: false);
              await provider.refreshExternalContent();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content refreshed!')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showStatsInfo(),
          ),
        ],
      ),
      body: Consumer<MeditationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Source Filter
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Content Sources',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SourceFilterChips(
                      sources: provider.availableSources,
                      selectedSource: provider.selectedSource,
                      onSourceSelected: provider.setSource,
                    ),
                  ],
                ),
              ),

              // Pagination Info
              if (provider.externalMeditations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        provider.getPaginationInfo(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (provider.hasNextPage)
                        Text(
                          'Scroll for more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),

              // Error Display
              if (provider.externalError != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.externalError!,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                      TextButton(
                        onPressed: provider.clearExternalError,
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),

              // Content
              Expanded(
                child: _buildContent(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(MeditationProvider provider) {
    if (provider.isLoadingExternal && provider.externalMeditations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading external content...'),
            SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (provider.externalMeditations.isEmpty &&
        provider.externalError == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No external content found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different source or check your connection',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadExternalMeditations(
                source: provider.selectedSource,
                refresh: true,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadExternalMeditations(
        source: provider.selectedSource,
        refresh: true,
      ),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final meditation = provider.externalMeditations[index];
                  return ExternalMeditationCard(
                    meditation: meditation,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/meditation-detail',
                        arguments: {'meditation': meditation},
                      );
                    },
                  );
                },
                childCount: provider.externalMeditations.length,
              ),
            ),
          ),

          // Loading more indicator
          if (provider.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Loading more content...'),
                    ],
                  ),
                ),
              ),
            ),

          // End of content indicator
          if (!provider.hasNextPage && provider.externalMeditations.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[400],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ve seen all content for ${provider.selectedSource}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different source to see more content',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showStatsInfo() {
    final provider = Provider.of<MeditationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Content Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow(
                  'Selected Source', provider.selectedSource.toUpperCase()),
              _buildStatRow('Total Available', '${provider.totalCount}'),
              _buildStatRow(
                  'Currently Loaded', '${provider.externalMeditations.length}'),
              _buildStatRow('Current Page',
                  '${provider.currentPage} of ${provider.totalPages}'),
              _buildStatRow('Per Page Limit', '${provider.perPage}'),
              _buildStatRow('Has More', provider.hasNextPage ? 'Yes' : 'No'),
              const SizedBox(height: 16),
              Text(
                'Content Sources:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...provider.availableSources.map((source) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          source == provider.selectedSource
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: source == provider.selectedSource
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(source == 'all'
                            ? 'All Sources'
                            : source.toUpperCase()),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label + ':',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }
}
