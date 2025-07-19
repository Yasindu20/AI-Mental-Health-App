import 'package:flutter/material.dart';
import 'package:frontend/widgets/external_meditation_card.dart';
import 'package:provider/provider.dart';
import '../providers/meditation_provider.dart';
import '../widgets/source_filter_chips.dart';

class ExternalContentScreen extends StatefulWidget {
  const ExternalContentScreen({super.key});

  @override
  State<ExternalContentScreen> createState() => _ExternalContentScreenState();
}

class _ExternalContentScreenState extends State<ExternalContentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MeditationProvider>(context, listen: false)
          .loadExternalMeditations();
    });
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
              await Provider.of<MeditationProvider>(context, listen: false)
                  .refreshContent();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content refreshed!')),
                );
              }
            },
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
    if (provider.isLoadingExternal) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading external content...'),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading content',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.loadExternalMeditations(
                source: provider.selectedSource,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (provider.externalMeditations.isEmpty) {
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
              'Check your internet connection or try a different source',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadExternalMeditations(
        source: provider.selectedSource,
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: provider.externalMeditations.length,
        itemBuilder: (context, index) {
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
      ),
    );
  }
}
