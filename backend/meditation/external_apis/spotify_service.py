# backend/meditation/external_apis/spotify_service.py
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
        # Try to get credentials from settings first, then environment
        config = getattr(settings, 'EXTERNAL_API_CONFIG', {})
        self.client_id = config.get('SPOTIFY_CLIENT_ID') or os.getenv('SPOTIFY_CLIENT_ID')
        self.client_secret = config.get('SPOTIFY_CLIENT_SECRET') or os.getenv('SPOTIFY_CLIENT_SECRET')
        self.access_token = None
        
        if self.client_id and self.client_secret:
            logger.info("Spotify credentials found and service initialized")
        else:
            logger.warning("Spotify credentials not found")
    
    def _get_access_token(self) -> str:
        """Get Spotify access token"""
        if not self.client_id or not self.client_secret:
            logger.error("Spotify credentials not configured")
            return ''
            
        cache_key = 'spotify_access_token'
        token = cache.get(cache_key)
        
        if token:
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
            
            response = requests.post(
                'https://accounts.spotify.com/api/token',
                headers=headers,
                data=data,
                timeout=10
            )
            response.raise_for_status()
            
            token_data = response.json()
            access_token = token_data['access_token']
            expires_in = token_data.get('expires_in', 3600)
            
            # Cache token for slightly less than expiry time
            cache.set(cache_key, access_token, expires_in - 60)
            
            logger.info("Spotify access token obtained successfully")
            return access_token
            
        except Exception as e:
            logger.error(f'Error getting Spotify access token: {str(e)}')
            return ''
    
    def search_meditation_playlists(self, max_results: int = 50) -> List[Dict]:
        """Search for meditation playlists on Spotify"""
        cache_key = f'spotify_playlists_{max_results}'
        cached_result = cache.get(cache_key)
        
        if cached_result:
            logger.info("Returning cached Spotify results")
            return cached_result
            
        access_token = self._get_access_token()
        if not access_token:
            logger.error("Cannot get Spotify access token")
            return []
            
        search_queries = [
            'meditation',
            'mindfulness',
            'guided meditation',
            'sleep meditation',
            'relaxation',
            'breathing exercises',
            'stress relief meditation',
            'anxiety meditation'
        ]
        
        all_tracks = []
        
        for query in search_queries:
            try:
                tracks = self._search_tracks(access_token, query, 
                                           limit=max_results // len(search_queries))
                all_tracks.extend(tracks)
                logger.info(f"Found {len(tracks)} tracks for query: {query}")
                
            except Exception as e:
                logger.error(f'Error searching Spotify for {query}: {str(e)}')
                continue
        
        # Process and filter tracks
        processed_tracks = self._process_spotify_tracks(all_tracks)
        unique_tracks = self._deduplicate_tracks(processed_tracks)
        
        # Cache for 4 hours
        cache.set(cache_key, unique_tracks, 14400)
        
        logger.info(f"Returning {len(unique_tracks)} unique Spotify tracks")
        return unique_tracks[:max_results]
    
    def _search_tracks(self, access_token: str, query: str, limit: int = 10) -> List[Dict]:
        """Search for tracks on Spotify"""
        headers = {'Authorization': f'Bearer {access_token}'}
        
        params = {
            'q': query,
            'type': 'track',
            'limit': limit,
            'market': 'US'
        }
        
        response = requests.get(
            'https://api.spotify.com/v1/search',
            headers=headers,
            params=params,
            timeout=10
        )
        response.raise_for_status()
        
        data = response.json()
        return data.get('tracks', {}).get('items', [])
    
    def _process_spotify_tracks(self, tracks: List[Dict]) -> List[Dict]:
        """Process Spotify tracks into our format"""
        processed = []
        
        for track in tracks:
            if not track:
                continue
                
            duration_ms = track.get('duration_ms', 0)
            duration_minutes = max(1, duration_ms // 60000)
            
            # Filter out very short tracks (less than 3 minutes)
            if duration_minutes < 3:
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
                'target_states': self._detect_spotify_target_states(track.get('name', ''))
            }
            
            processed.append(meditation)
            
        return processed
    
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
            'binaural': ['binaural', 'hz', 'frequency'],
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
            duration_boost = 1.2
        elif duration_minutes >= 20:
            duration_boost = 1.3
            
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

# Initialize service
spotify_service = SpotifyService()