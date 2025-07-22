from typing import List, Dict, Optional
from django.core.cache import cache
from django.conf import settings
import logging
import concurrent.futures

logger = logging.getLogger(__name__)

# Import services with comprehensive error handling
services_status = {
    'youtube': False,
    'spotify': False,
    'huggingface': False
}

# YouTube service
try:
    from .youtube_service import youtube_service
    if youtube_service:
        services_status['youtube'] = True
        logger.info("YouTube service loaded successfully")
    else:
        logger.warning("YouTube service failed to initialize")
except Exception as e:
    youtube_service = None
    logger.error(f"YouTube service import error: {e}")

# Spotify service
try:
    from .spotify_service import spotify_service
    if spotify_service:
        services_status['spotify'] = True
        logger.info("Spotify service loaded successfully")
    else:
        logger.warning("Spotify service failed to initialize")
except Exception as e:
    spotify_service = None
    logger.error(f"Spotify service import error: {e}")

# HuggingFace service
try:
    from .huggingface_service import huggingface_service
    if huggingface_service:
        services_status['huggingface'] = True
        logger.info("HuggingFace service loaded successfully")
    else:
        logger.warning("HuggingFace service failed to initialize")
except Exception as e:
    huggingface_service = None
    logger.error(f"HuggingFace service import error: {e}")

class ContentAggregator:
    def __init__(self):
        self.services = {}
        
        # Only add working services
        if services_status['youtube'] and youtube_service:
            self.services['youtube'] = youtube_service
            logger.info("YouTube service registered")
        
        if services_status['spotify'] and spotify_service:
            self.services['spotify'] = spotify_service
            logger.info("Spotify service registered")
            
        if services_status['huggingface'] and huggingface_service:
            self.services['huggingface'] = huggingface_service
            logger.info("HuggingFace service registered")
            
        logger.info(f"ContentAggregator initialized with {len(self.services)} working services: {list(self.services.keys())}")
    
    def get_all_external_content(self, sources: List[str] = None, 
                               max_per_source: int = 20) -> List[Dict]:
        """Aggregate content from all external sources"""
        if sources is None:
            sources = list(self.services.keys())
            
        # Filter to only available sources
        sources = [s for s in sources if s in self.services]
        
        if not sources:
            logger.warning("No valid sources available")
            return []
            
        cache_key = f'aggregated_content_{"+".join(sources)}_{max_per_source}'
        cached_result = cache.get(cache_key)
        
        if cached_result:
            logger.info(f"Returning cached content for sources: {sources}")
            return cached_result
            
        all_content = []
        
        # Use thread pool for concurrent API calls (reduced workers to be conservative)
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            futures = {}
            
            for source in sources:
                if source in self.services:
                    future = executor.submit(self._get_content_from_source, 
                                           source, max_per_source)
                    futures[future] = source
            
            for future in concurrent.futures.as_completed(futures):
                source = futures[future]
                try:
                    content = future.result(timeout=45)  # Increased timeout
                    if content:
                        all_content.extend(content)
                        logger.info(f'Retrieved {len(content)} items from {source}')
                    else:
                        logger.warning(f'No content retrieved from {source}')
                except Exception as e:
                    logger.error(f'Error getting content from {source}: {str(e)}')
        
        # Sort by effectiveness score
        all_content.sort(key=lambda x: x.get('effectiveness_score', 0), reverse=True)
        
        # Cache for 1 hour (reduced cache time for testing)
        cache.set(cache_key, all_content, 3600)
        
        logger.info(f"Total content aggregated: {len(all_content)} items")
        return all_content
    
    def _get_content_from_source(self, source: str, max_results: int) -> List[Dict]:
        """Get content from a specific source"""
        service = self.services.get(source)
        if not service:
            logger.warning(f"Service not available for source: {source}")
            return []
            
        try:
            logger.info(f"Getting content from {source} service...")
            
            if source == 'youtube':
                content = service.search_meditations(max_results=max_results)
            elif source == 'spotify':
                content = service.search_meditation_playlists(max_results=max_results)
            elif source == 'huggingface':
                content = service.search_meditation_datasets(max_results=max_results)
            else:
                logger.warning(f"Unknown source type: {source}")
                return []
                
            logger.info(f"Retrieved {len(content)} items from {source}")
            return content
                
        except Exception as e:
            logger.error(f'Error in {source} service: {str(e)}', exc_info=True)
            return []
    
    def search_external_content(self, query: str, sources: List[str] = None,
                              max_results: int = 20) -> List[Dict]:
        """Search external content with a specific query"""
        all_content = self.get_all_external_content(sources)
        
        if not query:
            return all_content[:max_results]
            
        query_lower = query.lower()
        
        # Score content based on query relevance
        scored_content = []
        for content in all_content:
            score = self._calculate_relevance_score(content, query_lower)
            if score > 0:
                content['relevance_score'] = score
                scored_content.append(content)
        
        # Sort by relevance and effectiveness
        scored_content.sort(
            key=lambda x: (x.get('relevance_score', 0) * 0.7 + 
                          x.get('effectiveness_score', 0) * 0.3),
            reverse=True
        )
        
        return scored_content[:max_results]
    
    def _calculate_relevance_score(self, content: Dict, query: str) -> float:
        """Calculate relevance score for search query"""
        text_fields = [
            content.get('name', ''),
            content.get('description', ''),
            ' '.join(content.get('tags', [])),
            ' '.join(content.get('target_states', []))
        ]
        
        full_text = ' '.join(text_fields).lower()
        query_words = query.split()
        
        score = 0
        for word in query_words:
            if word in full_text:
                # Boost score for exact matches in title
                if word in content.get('name', '').lower():
                    score += 2
                else:
                    score += 1
                    
        return min(1.0, score / len(query_words)) if query_words else 0
    
    def get_personalized_recommendations(self, user_preferences: Dict,
                                       max_results: int = 10) -> List[Dict]:
        """Get personalized content recommendations"""
        all_content = self.get_all_external_content()
        
        # Score content based on user preferences
        scored_content = []
        for content in all_content:
            score = self._calculate_personalization_score(content, user_preferences)
            content['personalization_score'] = score
            scored_content.append(content)
        
        # Sort by personalization and effectiveness
        scored_content.sort(
            key=lambda x: (x.get('personalization_score', 0) * 0.6 + 
                          x.get('effectiveness_score', 0) * 0.4),
            reverse=True
        )
        
        return scored_content[:max_results]
    
    def _calculate_personalization_score(self, content: Dict, 
                                       preferences: Dict) -> float:
        """Calculate personalization score based on user preferences"""
        score = 0.5  # Base score
        
        # Preferred types
        preferred_types = preferences.get('preferred_types', [])
        if content.get('type') in preferred_types:
            score += 0.3
            
        # Preferred duration
        preferred_duration = preferences.get('preferred_duration', 15)
        content_duration = content.get('duration_minutes', 15)
        duration_diff = abs(content_duration - preferred_duration)
        
        if duration_diff <= 5:
            score += 0.2
        elif duration_diff <= 10:
            score += 0.1
            
        # Preferred sources
        preferred_sources = preferences.get('preferred_sources', [])
        if content.get('source') in preferred_sources:
            score += 0.2
            
        # Target states match
        preferred_states = preferences.get('target_states', [])
        content_states = content.get('target_states', [])
        
        if any(state in content_states for state in preferred_states):
            score += 0.3
            
        return min(1.0, score)
    
    def get_service_status(self) -> Dict[str, bool]:
        """Get status of all services"""
        return services_status.copy()

# Initialize aggregator
content_aggregator = ContentAggregator()