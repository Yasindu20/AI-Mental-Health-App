import os
import requests
from typing import List, Dict, Optional
from django.core.cache import cache
from django.conf import settings
import logging
import re

logger = logging.getLogger(__name__)

class YouTubeService:
    def __init__(self):
        # Get API key from settings first, then environment
        config = getattr(settings, 'EXTERNAL_API_CONFIG', {})
        self.api_key = config.get('YOUTUBE_API_KEY') or os.getenv('YOUTUBE_API_KEY', '').strip()
        self.base_url = 'https://www.googleapis.com/youtube/v3'
        
        logger.info(f"YouTube API key present: {'Yes' if self.api_key else 'No'}")
        if self.api_key:
            logger.info(f"YouTube API key: {self.api_key[:10]}...")
    
    def test_api_connection(self) -> bool:
        """Test if the YouTube API is working"""
        if not self.api_key:
            logger.error("No YouTube API key configured")
            return False
            
        try:
            params = {
                'part': 'snippet',
                'q': 'meditation test',
                'key': self.api_key,
                'type': 'video',
                'maxResults': 1,
            }
            
            response = requests.get(f'{self.base_url}/search', params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if 'items' in data and len(data['items']) > 0:
                    logger.info("YouTube API connection successful")
                    return True
                else:
                    logger.error(f"YouTube API returned no items: {data}")
                    return False
            elif response.status_code == 403:
                logger.error(f"YouTube API access forbidden - check API key and quota: {response.text}")
                return False
            else:
                logger.error(f"YouTube API error: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"YouTube API connection test failed: {str(e)}")
            return False
    
    def search_meditations(self, query: str = 'guided meditation', 
                          max_results: int = 25) -> List[Dict]:
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
            'guided meditation for beginners',
            'mindfulness meditation 10 minutes',
            'breathing meditation relaxation',
            'sleep meditation anxiety relief'
        ]
        
        all_videos = []
        
        for search_query in search_queries[:2]:  # Limit to 2 queries to conserve quota
            try:
                params = {
                    'part': 'snippet',
                    'q': search_query,
                    'key': self.api_key,
                    'type': 'video',
                    'maxResults': min(10, max_results // 2),
                    'videoDuration': 'medium',  # 4-20 minutes
                    'order': 'relevance',
                    'safeSearch': 'strict',
                    'videoDefinition': 'any'
                }
                
                logger.info(f"Searching YouTube: {search_query}")
                response = requests.get(f'{self.base_url}/search', params=params, timeout=15)
                
                if response.status_code == 403:
                    logger.error("YouTube API quota exceeded or forbidden")
                    break
                    
                if response.status_code != 200:
                    logger.error(f"YouTube API error: {response.status_code} - {response.text}")
                    continue
                
                data = response.json()
                items = data.get('items', [])
                logger.info(f"YouTube returned {len(items)} items for: {search_query}")
                
                videos = self._process_youtube_videos(items)
                all_videos.extend(videos)
                logger.info(f"Processed {len(videos)} videos for query: {search_query}")
                
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
            try:
                snippet = item.get('snippet', {})
                video_id = item.get('id', {}).get('videoId')
                
                if not video_id:
                    continue
                    
                # Get additional video details (optional, uses more quota)
                video_details = self._get_video_details(video_id)
                
                meditation = {
                    'id': f'youtube_{video_id}',
                    'name': snippet.get('title', '').replace('&quot;', '"'),
                    'description': snippet.get('description', '')[:500],
                    'source': 'youtube',
                    'external_id': video_id,
                    'video_url': f'https://www.youtube.com/watch?v={video_id}',
                    'thumbnail_url': self._get_best_thumbnail(snippet),
                    'duration_minutes': self._parse_duration(video_details.get('duration')) if video_details else 15,
                    'type': self._detect_meditation_type(snippet.get('title', '')),
                    'level': self._detect_difficulty_level(snippet.get('title', '')),
                    'channel_name': snippet.get('channelTitle', ''),
                    'published_at': snippet.get('publishedAt'),
                    'view_count': video_details.get('viewCount', 0) if video_details else 0,
                    'like_count': video_details.get('likeCount', 0) if video_details else 0,
                    'effectiveness_score': self._calculate_effectiveness_score(video_details) if video_details else 0.7,
                    'tags': self._extract_meditation_tags(snippet.get('title', '') + ' ' + snippet.get('description', '')),
                    'target_states': self._detect_target_states(snippet.get('title', '') + ' ' + snippet.get('description', '')),
                    'is_free': True,
                    'requires_subscription': False,
                    'language': 'en'
                }
                
                processed.append(meditation)
                
            except Exception as e:
                logger.error(f'Error processing YouTube video: {str(e)}')
                continue
        
        return processed
    
    def _get_video_details(self, video_id: str) -> Dict:
        """Get detailed video information (uses additional API quota)"""
        try:
            params = {
                'part': 'contentDetails,statistics',
                'id': video_id,
                'key': self.api_key
            }
            
            response = requests.get(f'{self.base_url}/videos', params=params, timeout=10)
            
            if response.status_code != 200:
                logger.warning(f'Could not get video details for {video_id}: {response.status_code}')
                return {}
            
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
            logger.warning(f'Error getting video details: {str(e)}')
            
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
            return 15
            
        match = re.match(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?', iso_duration)
        
        if match:
            hours = int(match.group(1) or 0)
            minutes = int(match.group(2) or 0)
            seconds = int(match.group(3) or 0)
            
            total_minutes = hours * 60 + minutes + (seconds // 60)
            return max(1, min(total_minutes, 120))  # Cap at 2 hours
            
        return 15
    
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
                   len(set(title.split()) & set(seen.split())) > len(title.split()) * 0.7
                   for seen in seen_titles):
                continue
                
            # Filter out very short or very long videos
            duration = video['duration_minutes']
            if duration < 3 or duration > 120:
                continue
                
            seen_titles.add(title)
            filtered.append(video)
            
        return filtered

# Initialize service
youtube_service = None
try:
    youtube_service = YouTubeService()
    connection_status = youtube_service.test_api_connection()
    logger.info(f"YouTube service initialized. Connection: {'OK' if connection_status else 'FAILED'}")
except Exception as e:
    logger.error(f"Failed to initialize YouTube service: {str(e)}")