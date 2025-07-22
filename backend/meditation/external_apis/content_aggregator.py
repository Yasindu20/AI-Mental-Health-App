from typing import List, Dict, Optional
from django.core.cache import cache
from django.conf import settings
import logging
import concurrent.futures
import math

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
    
    def get_paginated_external_content(self, sources: List[str] = None, 
                                     page: int = 1, per_page: int = 20,
                                     search_query: str = '') -> Dict:
        """NEW: Get paginated content from external sources with TRUE infinite scroll support"""
        if sources is None:
            sources = list(self.services.keys())
            
        # Filter to only available sources
        sources = [s for s in sources if s in self.services]
        
        if not sources:
            logger.warning("No valid sources available")
            return {
                'results': [],
                'total_count': 0,
                'has_next': False,
                'page': page
            }
        
        # Cache key includes page for proper pagination caching
        cache_key = f'paginated_content_{"+".join(sources)}_{page}_{per_page}_{hash(search_query)}'
        cached_result = cache.get(cache_key)
        
        if cached_result:
            logger.info(f"Returning cached paginated content for sources: {sources}, page: {page}")
            return cached_result
        
        all_content = []
        total_available = 0
        
        # Calculate how much content to request from each source
        # For 'all' sources, distribute the per_page across sources
        if len(sources) == 1:
            items_per_source = per_page
        else:
            items_per_source = max(10, per_page // len(sources))
        
        # Use thread pool for concurrent API calls
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            futures = {}
            
            for source in sources:
                if source in self.services:
                    future = executor.submit(self._get_paginated_content_from_source, 
                                           source, page, items_per_source, search_query)
                    futures[future] = source
            
            for future in concurrent.futures.as_completed(futures):
                source = futures[future]
                try:
                    source_response = future.result(timeout=45)
                    if source_response:
                        all_content.extend(source_response['content'])
                        total_available += source_response['total_available']
                        logger.info(f'Retrieved {len(source_response["content"])} items from {source} (page {page})')
                    else:
                        logger.warning(f'No content retrieved from {source}')
                except Exception as e:
                    logger.error(f'Error getting paginated content from {source}: {str(e)}')
        
        # Sort by effectiveness score
        all_content.sort(key=lambda x: x.get('effectiveness_score', 0), reverse=True)
        
        # For multiple sources, we need to estimate total available content
        if len(sources) > 1:
            # Estimate based on what we know from each source
            estimated_total = max(total_available, len(all_content) * 2)  # Conservative estimate
        else:
            estimated_total = total_available
        
        # Determine if there are more pages
        # This is the KEY to infinite scroll working!
        has_next = self._determine_has_next_page(all_content, page, per_page, estimated_total, sources)
        
        result = {
            'results': all_content[:per_page],  # Ensure we don't exceed requested per_page
            'total_count': estimated_total,
            'has_next': has_next,
            'page': page,
            'per_page': per_page
        }
        
        # Cache for 30 minutes (shorter cache for better real-time experience)
        cache.set(cache_key, result, 1800)
        
        logger.info(f"Returning paginated content: {len(result['results'])} items, has_next: {has_next}, total_estimated: {estimated_total}")
        return result
    
    def _get_paginated_content_from_source(self, source: str, page: int, 
                                         max_results: int, search_query: str = '') -> Optional[Dict]:
        """Get paginated content from a specific source"""
        service = self.services.get(source)
        if not service:
            logger.warning(f"Service not available for source: {source}")
            return None
            
        try:
            logger.info(f"Getting paginated content from {source} service (page {page}, max_results: {max_results})")
            
            if source == 'youtube':
                # YouTube can provide lots of content, paginate properly
                response = service.search_paginated_meditations(
                    page=page, 
                    max_results=max_results,
                    search_query=search_query
                )
            elif source == 'spotify':
                response = service.search_paginated_meditation_playlists(
                    page=page,
                    max_results=max_results,
                    search_query=search_query
                )
            elif source == 'huggingface':
                # HuggingFace can generate unlimited content
                response = service.generate_paginated_meditations(
                    page=page,
                    max_results=max_results
                )
            else:
                logger.warning(f"Unknown source type: {source}")
                return None
                
            logger.info(f"Retrieved {len(response['content']) if response else 0} items from {source} (page {page})")
            return response
                
        except Exception as e:
            logger.error(f'Error in {source} paginated service: {str(e)}', exc_info=True)
            return None
    
    def _determine_has_next_page(self, content: List[Dict], page: int, per_page: int, 
                               estimated_total: int, sources: List[str]) -> bool:
        """Determine if there are more pages available - KEY METHOD for infinite scroll"""
        
        # If we got fewer results than requested, probably no more content
        if len(content) < per_page and page > 1:
            return False
        
        # For single source, use source-specific logic
        if len(sources) == 1:
            source = sources[0]
            
            # YouTube: Virtually unlimited content (API quota permitting)
            if source == 'youtube':
                return page < 50  # Limit to 50 pages (1000 videos) to respect API quotas
                
            # Spotify: Lots of content available
            elif source == 'spotify':
                return page < 30  # Limit to 30 pages (600 tracks)
                
            # HuggingFace: Can generate unlimited content
            elif source == 'huggingface':
                return page < 100  # Very high limit for AI-generated content
        
        # For 'all' sources combined, be more conservative but still allow many pages
        else:
            # Allow many pages for 'all' sources combined
            return page < 25  # 25 pages * 20 per page = 500 total items for 'all'
        
        # Default fallback
        return estimated_total > (page * per_page)

    # Keep existing methods for backward compatibility
    def get_all_external_content(self, sources: List[str] = None, 
                               max_per_source: int = 20) -> List[Dict]:
        """Legacy method - redirects to paginated version"""
        paginated_response = self.get_paginated_external_content(
            sources=sources, 
            page=1, 
            per_page=max_per_source * (len(sources) if sources else 3)
        )
        return paginated_response['results']

    # ... rest of the existing methods remain the same
    
    def get_service_status(self) -> Dict[str, bool]:
        """Get status of all services"""
        return services_status.copy()

# Initialize aggregator
content_aggregator = ContentAggregator()