# backend/meditation/external_apis/youtube_service.py
import os
import requests
from typing import List, Dict, Optional
from django.core.cache import cache
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

class YouTubeService:
    def __init__(self):
        # Try to get API key from settings first, then environment
        self.api_key = (
            getattr(settings, 'EXTERNAL_API_CONFIG', {}).get('YOUTUBE_API_KEY') or
            os.getenv('YOUTUBE_API_KEY')
        )
        self.base_url = 'https://www.googleapis.com/youtube/v3'
        
        if self.api_key:
            logger.info("YouTube API key found and service initialized")
        else:
            logger.warning("YouTube API key not found")
    
    def search_meditations(self, query: str = 'guided meditation', 
                          max_results: int = 50) -> List[Dict]:
        """Search for meditation videos on YouTube"""
        if not self.api_key:
            logger.error("YouTube API key not configured")
            return []
            
        cache_key = f'youtube_search_{query}_{max_results}'
        cached_result = cache.get(cache_key)
        
        if cached_result:
            logger.info(f"Returning cached YouTube results for: {query}")
            return cached_result
            
        search_queries = [
            f'{query} mindfulness',
            f'{query} breathing',
            f'{query} sleep meditation',
            f'{query} anxiety relief',
            f'{query} stress relief',
            'body scan meditation',
            'loving kindness meditation',
            'meditation for beginners'
        ]
        
        all_videos = []
        
        for search_query in search_queries:
            try:
                params = {
                    'part': 'snippet',
                    'q': search_query,
                    'key': self.api_key,
                    'type': 'video',
                    'maxResults': min(10, max_results // len(search_queries)),
                    'videoDuration': 'medium',  # 4-20 minutes
                    'videoDefinition': 'high',
                    'order': 'relevance'
                }
                
                response = requests.get(f'{self.base_url}/search', params=params)
                response.raise_for_status()
                
                data = response.json()
                videos = self._process_youtube_videos(data.get('items', []))
                all_videos.extend(videos)
                logger.info(f"Found {len(videos)} videos for query: {search_query}")
                
            except Exception as e:
                logger.error(f'Error searching YouTube for "{search_query}": {str(e)}')
                continue
        
        # Remove duplicates and filter quality
        unique_videos = self._deduplicate_and_filter(all_videos)
        
        # Cache for 6 hours
        cache.set(cache_key, unique_videos, 21600)
        
        logger.info(f"Returning {len(unique_videos)} unique YouTube videos")
        return unique_videos[:max_results]
    
    def _process_youtube_videos(self, items: List[Dict]) -> List[Dict]:
        """Process YouTube API response into our format"""
        processed = []
        
        for item in items:
            snippet = item.get('snippet', {})
            video_id = item.get('id', {}).get('videoId')
            
            if not video_id:
                continue
                
            # Get additional video details
            video_details = self._get_video_details(video_id)
            
            meditation = {
                'id': f'youtube_{video_id}',
                'name': snippet.get('title', '').replace('&quot;', '"'),
                'description': snippet.get('description', '')[:500],
                'source': 'youtube',
                'external_id': video_id,
                'video_url': f'https://www.youtube.com/watch?v={video_id}',
                'thumbnail_url': self._get_best_thumbnail(snippet),
                'duration_minutes': self._parse_duration(video_details.get('duration')),
                'type': self._detect_meditation_type(snippet.get('title', '')),
                'level': self._detect_difficulty_level(snippet.get('title', '')),
                'channel_name': snippet.get('channelTitle', ''),
                'published_at': snippet.get('publishedAt'),
                'view_count': video_details.get('viewCount', 0),
                'like_count': video_details.get('likeCount', 0),
                'effectiveness_score': self._calculate_effectiveness_score(video_details),
                'tags': self._extract_meditation_tags(snippet.get('title', '') + ' ' + snippet.get('description', '')),
                'target_states': self._detect_target_states(snippet.get('title', '') + ' ' + snippet.get('description', ''))
            }
            
            processed.append(meditation)
            
        return processed
    
    def _get_video_details(self, video_id: str) -> Dict:
        """Get detailed video information"""
        try:
            params = {
                'part': 'contentDetails,statistics',
                'id': video_id,
                'key': self.api_key
            }
            
            response = requests.get(f'{self.base_url}/videos', params=params)
            response.raise_for_status()
            
            data = response.json()
            if data.get('items'):
                item = data['items'][0]
                return {
                    'duration': item.get('contentDetails', {}).get('duration'),
                    'viewCount': int(item.get('statistics', {}).get('viewCount', 0)),
                    'likeCount': int(item.get('statistics', {}).get('likeCount', 0)),
                    'commentCount': int(item.get('statistics', {}).get('commentCount', 0))
                }
        except Exception as e:
            logger.error(f'Error getting video details: {str(e)}')
            
        return {}
    
    def _get_best_thumbnail(self, snippet: Dict) -> str:
        """Get the best available thumbnail"""
        thumbnails = snippet.get('thumbnails', {})
        
        for quality in ['maxres', 'standard', 'high', 'medium', 'default']:
            if quality in thumbnails:
                return thumbnails[quality]['url']
                
        return ''
    
    def _parse_duration(self, iso_duration: str) -> int:
        """Parse ISO 8601 duration to minutes"""
        if not iso_duration:
            return 10
            
        import re
        match = re.match(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?', iso_duration)
        
        if match:
            hours = int(match.group(1) or 0)
            minutes = int(match.group(2) or 0)
            seconds = int(match.group(3) or 0)
            
            total_minutes = hours * 60 + minutes + (seconds // 60)
            return max(1, total_minutes)
            
        return 10
    
    def _detect_meditation_type(self, title: str) -> str:
        """Detect meditation type from title"""
        title_lower = title.lower()
        
        type_keywords = {
            'breathing': ['breathing', 'breath', 'pranayama'],
            'body_scan': ['body scan', 'progressive', 'muscle'],
            'mindfulness': ['mindfulness', 'awareness', 'present'],
            'loving_kindness': ['loving kindness', 'compassion', 'metta'],
            'visualization': ['visualization', 'imagine', 'journey'],
            'sleep': ['sleep', 'bedtime', 'insomnia'],
            'movement': ['walking', 'movement', 'tai chi', 'yoga']
        }
        
        for med_type, keywords in type_keywords.items():
            if any(keyword in title_lower for keyword in keywords):
                return med_type
                
        return 'mindfulness'
    
    def _detect_difficulty_level(self, title: str) -> str:
        """Detect difficulty level from title"""
        title_lower = title.lower()
        
        if any(word in title_lower for word in ['beginner', 'start', 'introduction', 'basic']):
            return 'beginner'
        elif any(word in title_lower for word in ['advanced', 'deep', 'intensive']):
            return 'advanced'
        else:
            return 'intermediate'
    
    def _extract_meditation_tags(self, text: str) -> List[str]:
        """Extract relevant tags from text"""
        text_lower = text.lower()
        
        tag_keywords = {
            'stress_relief': ['stress', 'tension', 'pressure'],
            'anxiety': ['anxiety', 'worry', 'nervous'],
            'sleep': ['sleep', 'bedtime', 'insomnia'],
            'focus': ['focus', 'concentration', 'attention'],
            'healing': ['healing', 'recovery', 'wellness'],
            'gratitude': ['gratitude', 'thankful', 'appreciation'],
            'self_love': ['self love', 'self compassion', 'self care']
        }
        
        tags = []
        for tag, keywords in tag_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                tags.append(tag)
                
        return tags
    
    def _detect_target_states(self, text: str) -> List[str]:
        """Detect target emotional states"""
        text_lower = text.lower()
        
        states = []
        state_keywords = {
            'relaxation': ['relax', 'calm', 'peace'],
            'energy': ['energy', 'vitality', 'awakening'],
            'happiness': ['happiness', 'joy', 'positive'],
            'confidence': ['confidence', 'strength', 'power'],
            'clarity': ['clarity', 'clear', 'insight']
        }
        
        for state, keywords in state_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                states.append(state)
                
        return states or ['relaxation']
    
    def _calculate_effectiveness_score(self, video_details: Dict) -> float:
        """Calculate effectiveness score based on engagement metrics"""
        view_count = video_details.get('viewCount', 0)
        like_count = video_details.get('likeCount', 0)
        
        if view_count == 0:
            return 0.5
            
        like_ratio = like_count / view_count if view_count > 0 else 0
        
        # Normalize scores
        view_score = min(view_count / 100000, 1.0)  # Up to 100k views = 1.0
        engagement_score = min(like_ratio * 100, 1.0)  # Up to 1% like ratio = 1.0
        
        # Weighted average
        final_score = (view_score * 0.3 + engagement_score * 0.7)
        
        return max(0.1, min(1.0, final_score))
    
    def _deduplicate_and_filter(self, videos: List[Dict]) -> List[Dict]:
        """Remove duplicates and filter low-quality content"""
        seen_titles = set()
        filtered = []
        
        for video in videos:
            title = video['name'].lower()
            
            # Skip if we've seen similar title
            if any(abs(len(title) - len(seen)) < 5 and 
                   set(title.split()) & set(seen.split()) 
                   for seen in seen_titles):
                continue
                
            # Filter out very short or very long videos
            duration = video['duration_minutes']
            if duration < 3 or duration > 90:
                continue
                
            # Filter out low-quality content
            if video['view_count'] < 100:  # Lowered threshold for testing
                continue
                
            seen_titles.add(title)
            filtered.append(video)
            
        return filtered

# Initialize service
youtube_service = YouTubeService()