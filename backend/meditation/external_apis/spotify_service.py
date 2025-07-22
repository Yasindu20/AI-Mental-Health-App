import os
import base64
import requests
from typing import List, Dict, Optional
from django.core.cache import cache
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

class SpotifyService:
    def __init__(self):
        # Get credentials from settings first, then environment
        config = getattr(settings, 'EXTERNAL_API_CONFIG', {})
        self.client_id = config.get('SPOTIFY_CLIENT_ID') or os.getenv('SPOTIFY_CLIENT_ID', '').strip()
        self.client_secret = config.get('SPOTIFY_CLIENT_SECRET') or os.getenv('SPOTIFY_CLIENT_SECRET', '').strip()
        self.access_token = None
        
        # Predefined search queries for variety across pages
        self.meditation_queries = [
            'meditation music',
            'mindfulness ambient',
            'relaxation sounds',
            'sleep meditation',
            'nature sounds meditation',
            'chakra meditation music',
            'binaural beats meditation',
            'zen meditation music',
            'yoga meditation',
            'stress relief music',
            'healing meditation',
            'deep relaxation music',
            'meditation piano',
            'tibetan singing bowls',
            'forest meditation sounds',
        ]
        
        logger.info(f"Spotify client_id present: {'Yes' if self.client_id else 'No'}")
        logger.info(f"Spotify client_secret present: {'Yes' if self.client_secret else 'No'}")
        if self.client_id:
            logger.info(f"Spotify client_id: {self.client_id[:10]}...")
    
    def test_api_connection(self) -> bool:
        """Test if the Spotify API is working"""
        if not self.client_id or not self.client_secret:
            logger.error("Spotify credentials not configured")
            return False
            
        try:
            access_token = self._get_access_token()
            if access_token:
                # Test with a simple search
                headers = {'Authorization': f'Bearer {access_token}'}
                params = {'q': 'meditation', 'type': 'track', 'limit': 1}
                
                response = requests.get(
                    'https://api.spotify.com/v1/search',
                    headers=headers,
                    params=params,
                    timeout=10
                )
                
                if response.status_code == 200:
                    data = response.json()
                    if 'tracks' in data and data['tracks']['items']:
                        logger.info("Spotify API connection successful")
                        return True
                    else:
                        logger.error(f"Spotify API returned no tracks: {data}")
                        return False
                else:
                    logger.error(f"Spotify API error: {response.status_code} - {response.text}")
                    return False
            else:
                logger.error("Failed to get Spotify access token")
                return False
                
        except Exception as e:
            logger.error(f"Spotify API connection test failed: {str(e)}")
            return False
    
    def _get_access_token(self) -> str:
        """Get Spotify access token"""
        if not self.client_id or not self.client_secret:
            logger.error("Spotify credentials not configured")
            return ''
            
        cache_key = 'spotify_access_token'
        token = cache.get(cache_key)
        
        if token:
            logger.debug("Using cached Spotify token")
            return token
            
        try:
            # Encode credentials
            credentials = base64.b64encode(
                f'{self.client_id}:{self.client_secret}'.encode()
            ).decode()
            
            headers = {
                'Authorization': f'Basic {credentials}',
                'Content-Type': 'application/x-www-form-urlencoded'
            }
            
            data = {'grant_type': 'client_credentials'}
            
            logger.info("Requesting Spotify access token...")
            response = requests.post(
                'https://accounts.spotify.com/api/token',
                headers=headers,
                data=data,
                timeout=10
            )
            
            if response.status_code != 200:
                logger.error(f"Spotify token request failed: {response.status_code} - {response.text}")
                return ''
                
            token_data = response.json()
            access_token = token_data.get('access_token')
            expires_in = token_data.get('expires_in', 3600)
            
            if access_token:
                # Cache token for slightly less than expiry time
                cache.set(cache_key, access_token, expires_in - 60)
                logger.info("Spotify access token obtained successfully")
                return access_token
            else:
                logger.error(f"No access token in Spotify response: {token_data}")
                return ''
            
        except Exception as e:
            logger.error(f'Error getting Spotify access token: {str(e)}')
            return ''
    
    def search_paginated_meditation_playlists(self, page: int = 1, max_results: int = 20, 
                                            search_query: str = '') -> Dict:
        """NEW: Search for meditation content with proper pagination support"""
        access_token = self._get_access_token()
        if not access_token:
            logger.error("Cannot get Spotify access token")
            return {'content': [], 'total_available': 0}
        
        try:
            # Use custom search query or cycle through predefined queries
            if search_query:
                query = f"{search_query} meditation"
            else:
                # Cycle through different queries for different pages
                query_index = (page - 1) % len(self.meditation_queries)
                query = self.meditation_queries[query_index]
            
            logger.info(f"Spotify paginated search: '{query}' (page {page})")
            
            all_tracks = []
            
            # Calculate offset for pagination
            offset = (page - 1) * max_results
            
            # Search for tracks
            tracks = self._search_tracks_paginated(access_token, query, max_results, offset)
            all_tracks.extend(tracks)
            
            # Also search for playlists/albums for variety (every 3rd page)
            if page % 3 == 0:
                playlist_tracks = self._search_playlist_tracks(access_token, query, max_results // 2)
                all_tracks.extend(playlist_tracks)
            
            # Process and filter tracks
            processed_tracks = self._process_spotify_tracks(all_tracks)
            unique_tracks = self._deduplicate_tracks(processed_tracks)
            
            # Estimate total available content
            # Spotify has lots of meditation content, so we can be generous with estimates
            estimated_total = min(1000, max_results * 30)  # Cap at 1000 for performance
            
            return {
                'content': unique_tracks[:max_results],
                'total_available': estimated_total
            }
            
        except Exception as e:
            logger.error(f'Error in Spotify paginated search: {str(e)}')
            return {'content': [], 'total_available': 0}
    
    def _search_tracks_paginated(self, access_token: str, query: str, 
                               limit: int, offset: int) -> List[Dict]:
        """Search for tracks with pagination support"""
        headers = {'Authorization': f'Bearer {access_token}'}
        
        params = {
            'q': query,
            'type': 'track',
            'limit': min(50, limit),  # Spotify max is 50
            'offset': offset,
            'market': 'US'
        }
        
        response = requests.get(
            'https://api.spotify.com/v1/search',
            headers=headers,
            params=params,
            timeout=10
        )
        
        if response.status_code != 200:
            logger.error(f"Spotify track search failed: {response.status_code} - {response.text}")
            return []
            
        data = response.json()
        return data.get('tracks', {}).get('items', [])
    
    def _search_playlist_tracks(self, access_token: str, query: str, limit: int) -> List[Dict]:
        """Search for playlists and get tracks from them"""
        headers = {'Authorization': f'Bearer {access_token}'}
        
        # First, search for playlists
        params = {
            'q': query,
            'type': 'playlist',
            'limit': 5,  # Get a few playlists
            'market': 'US'
        }
        
        response = requests.get(
            'https://api.spotify.com/v1/search',
            headers=headers,
            params=params,
            timeout=10
        )
        
        if response.status_code != 200:
            return []
        
        playlists = response.json().get('playlists', {}).get('items', [])
        all_tracks = []
        
        # Get tracks from each playlist
        for playlist in playlists[:2]:  # Limit to 2 playlists
            playlist_id = playlist['id']
            
            try:
                tracks_response = requests.get(
                    f'https://api.spotify.com/v1/playlists/{playlist_id}/tracks',
                    headers=headers,
                    params={'limit': limit // 2},  # Split limit across playlists
                    timeout=10
                )
                
                if tracks_response.status_code == 200:
                    tracks_data = tracks_response.json()
                    for item in tracks_data.get('items', []):
                        if item.get('track'):
                            all_tracks.append(item['track'])
                            
            except Exception as e:
                logger.warning(f'Error getting tracks from playlist {playlist_id}: {str(e)}')
                continue
        
        return all_tracks
    
    def _process_spotify_tracks(self, tracks: List[Dict]) -> List[Dict]:
        """Process Spotify tracks into our format"""
        processed = []
        
        for track in tracks:
            try:
                if not track:
                    continue
                    
                duration_ms = track.get('duration_ms', 0)
                duration_minutes = max(1, duration_ms // 60000)
                
                # Filter out very short tracks (less than 2 minutes)
                if duration_minutes < 2:
                    continue
                    
                meditation = {
                    'id': f'spotify_{track["id"]}',
                    'name': track.get('name', ''),
                    'description': f'Spotify meditation track by {self._get_artists_string(track)}',
                    'source': 'spotify',
                    'external_id': track['id'],
                    'audio_url': track.get('preview_url'),  # 30-second preview
                    'spotify_url': track.get('external_urls', {}).get('spotify'),
                    'thumbnail_url': self._get_album_image(track),
                    'duration_minutes': duration_minutes,
                    'type': self._detect_spotify_meditation_type(track.get('name', '')),
                    'level': 'beginner',  # Default for Spotify content
                    'artist_name': self._get_artists_string(track),
                    'album_name': track.get('album', {}).get('name', ''),
                    'popularity': track.get('popularity', 0),
                    'effectiveness_score': self._calculate_spotify_effectiveness(track),
                    'tags': self._extract_spotify_tags(track.get('name', '')),
                    'target_states': self._detect_spotify_target_states(track.get('name', '')),
                    'is_free': False,  # Spotify requires subscription
                    'requires_subscription': True,
                    'language': 'en'
                }
                
                processed.append(meditation)
                
            except Exception as e:
                logger.error(f'Error processing Spotify track: {str(e)}')
                continue
                
        return processed
    
    # Keep all existing helper methods unchanged
    def _get_artists_string(self, track: Dict) -> str:
        """Get formatted artists string"""
        artists = track.get('artists', [])
        return ', '.join([artist.get('name', '') for artist in artists])
    
    def _get_album_image(self, track: Dict) -> str:
        """Get album cover image URL"""
        album = track.get('album', {})
        images = album.get('images', [])
        
        if images:
            # Return the first (largest) image
            return images[0].get('url', '')
            
        return ''
    
    def _detect_spotify_meditation_type(self, name: str) -> str:
        """Detect meditation type from Spotify track name"""
        name_lower = name.lower()
        
        type_keywords = {
            'breathing': ['breath', 'breathing', 'pranayama'],
            'sleep': ['sleep', 'bedtime', 'night', 'dream'],
            'nature': ['rain', 'ocean', 'forest', 'birds', 'nature'],
            'ambient': ['ambient', 'atmospheric', 'space'],
            'mantra': ['mantra', 'chant', 'om']
        }
        
        for med_type, keywords in type_keywords.items():
            if any(keyword in name_lower for keyword in keywords):
                return med_type
                
        return 'ambient'
    
    def _extract_spotify_tags(self, name: str) -> List[str]:
        """Extract tags from Spotify track name"""
        name_lower = name.lower()
        
        tags = []
        tag_keywords = {
            'sleep': ['sleep', 'bedtime', 'night'],
            'relaxation': ['relax', 'calm', 'peaceful'],
            'nature': ['nature', 'rain', 'ocean', 'forest'],
            'healing': ['healing', 'therapy', 'wellness'],
            'focus': ['focus', 'concentration', 'study']
        }
        
        for tag, keywords in tag_keywords.items():
            if any(keyword in name_lower for keyword in keywords):
                tags.append(tag)
                
        return tags
    
    def _detect_spotify_target_states(self, name: str) -> List[str]:
        """Detect target states from track name"""
        name_lower = name.lower()
        
        states = []
        state_keywords = {
            'relaxation': ['relax', 'calm', 'peace', 'tranquil'],
            'sleep': ['sleep', 'rest', 'bedtime'],
            'focus': ['focus', 'concentration', 'clarity'],
            'healing': ['healing', 'recovery', 'restoration']
        }
        
        for state, keywords in state_keywords.items():
            if any(keyword in name_lower for keyword in keywords):
                states.append(state)
                
        return states or ['relaxation']
    
    def _calculate_spotify_effectiveness(self, track: Dict) -> float:
        """Calculate effectiveness score for Spotify track"""
        popularity = track.get('popularity', 0)
        
        # Normalize popularity (0-100) to our scale (0-1)
        popularity_score = popularity / 100.0
        
        # Boost score for longer tracks (better for meditation)
        duration_ms = track.get('duration_ms', 0)
        duration_minutes = duration_ms // 60000
        
        duration_boost = 1.0
        if duration_minutes >= 10:
            duration_boost = 1.1
        elif duration_minutes >= 5:
            duration_boost = 1.05
            
        final_score = min(1.0, popularity_score * duration_boost)
        
        return max(0.1, final_score)
    
    def _deduplicate_tracks(self, tracks: List[Dict]) -> List[Dict]:
        """Remove duplicate tracks"""
        seen_names = set()
        unique_tracks = []
        
        for track in tracks:
            name_key = track['name'].lower().strip()
            
            if name_key not in seen_names:
                seen_names.add(name_key)
                unique_tracks.append(track)
                
        return unique_tracks

    # Legacy method for backward compatibility
    def search_meditation_playlists(self, max_results: int = 20) -> List[Dict]:
        """Legacy method - redirects to paginated version"""
        result = self.search_paginated_meditation_playlists(page=1, max_results=max_results)
        return result['content']

# Initialize service
spotify_service = None
try:
    spotify_service = SpotifyService()
    connection_status = spotify_service.test_api_connection()
    logger.info(f"Spotify service initialized. Connection: {'OK' if connection_status else 'FAILED'}")
except Exception as e:
    logger.error(f"Failed to initialize Spotify service: {str(e)}")