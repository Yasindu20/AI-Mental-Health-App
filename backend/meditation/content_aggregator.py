import os
import json
import requests
from typing import List, Dict, Any
from datasets import load_dataset
from googleapiclient.discovery import build
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from django.conf import settings
from .models import Meditation, MeditationType

class ContentAggregator:
    def __init__(self):
        self.youtube_api_key = os.getenv('YOUTUBE_API_KEY')
        self.youtube = build('youtube', 'v3', developerKey=self.youtube_api_key)
        
        # Spotify setup
        self.spotify_client_id = os.getenv('SPOTIFY_CLIENT_ID')
        self.spotify_client_secret = os.getenv('SPOTIFY_CLIENT_SECRET')
        self.spotify = None
        
        if self.spotify_client_id and self.spotify_client_secret:
            client_credentials_manager = SpotifyClientCredentials(
                client_id=self.spotify_client_id,
                client_secret=self.spotify_client_secret
            )
            self.spotify = spotipy.Spotify(
                client_credentials_manager=client_credentials_manager
            )
    
    def load_huggingface_dataset(self) -> List[Dict]:
        """Load meditation dataset from Hugging Face"""
        try:
            print("Loading Hugging Face meditation dataset...")
            dataset = load_dataset("BuildaByte/Meditation-miniset-v0.2")
            
            meditations = []
            for item in dataset['train']:
                meditation_data = {
                    'name': f"Guided Meditation: {item.get('context', 'General Wellness')}",
                    'type': self._map_meditation_type(item.get('meditation_style', 'mindfulness')),
                    'level': item.get('user_experience_level', 'beginner'),
                    'duration_minutes': self._parse_duration(item.get('session_duration', '10-15 minutes')),
                    'description': item.get('meditation_guidance', 'A peaceful meditation session'),
                    'instructions': self._parse_instructions(item.get('meditation_guidance', '')),
                    'benefits': item.get('affirmations_and_mindfulness', '').split('.') if item.get('affirmations_and_mindfulness') else [],
                    'target_states': self._extract_target_states(item.get('context', '')),
                    'tags': item.get('suggested_techniques', '').split(',') if item.get('suggested_techniques') else [],
                    'source': 'huggingface',
                    'effectiveness_score': 0.8,  # Default good score
                    'instructor_name': 'AI Generated Content',
                    'subcategory': item.get('meditation_style', 'General'),
                }
                meditations.append(meditation_data)
            
            print(f"Loaded {len(meditations)} meditations from Hugging Face")
            return meditations
            
        except Exception as e:
            print(f"Error loading Hugging Face dataset: {e}")
            return []
    
    def search_youtube_meditations(self, queries: List[str], max_results_per_query: int = 50) -> List[Dict]:
        """Search for meditation videos on YouTube"""
        if not self.youtube_api_key:
            print("YouTube API key not configured")
            return []
        
        meditations = []
        
        for query in queries:
            try:
                print(f"Searching YouTube for: {query}")
                search_response = self.youtube.search().list(
                    q=query,
                    part='snippet',
                    type='video',
                    maxResults=max_results_per_query,
                    videoCategoryId='22',  # People & Blogs category
                    order='relevance',
                    safeSearch='strict'
                ).execute()
                
                for item in search_response['items']:
                    # Get additional video details
                    video_details = self.youtube.videos().list(
                        part='contentDetails,statistics',
                        id=item['id']['videoId']
                    ).execute()
                    
                    if video_details['items']:
                        video_info = video_details['items'][0]
                        duration = self._parse_youtube_duration(
                            video_info['contentDetails']['duration']
                        )
                        
                        meditation_data = {
                            'name': item['snippet']['title'][:200],  # Limit title length
                            'type': self._categorize_youtube_meditation(item['snippet']['title'], item['snippet']['description']),
                            'level': 'beginner',  # Default for YouTube content
                            'duration_minutes': duration,
                            'description': item['snippet']['description'][:500],  # Limit description
                            'instructions': self._generate_youtube_instructions(item['snippet']['title']),
                            'benefits': self._extract_benefits_from_description(item['snippet']['description']),
                            'target_states': self._extract_target_states_youtube(item['snippet']['title'], item['snippet']['description']),
                            'video_url': f"https://www.youtube.com/watch?v={item['id']['videoId']}",
                            'thumbnail_url': item['snippet']['thumbnails'].get('high', {}).get('url', ''),
                            'tags': [query.replace(' meditation', '').replace('meditation ', '')],
                            'source': 'youtube',
                            'effectiveness_score': min(0.9, float(video_info.get('statistics', {}).get('likeCount', 0)) / 1000 * 0.1 + 0.5),
                            'instructor_name': item['snippet']['channelTitle'],
                            'subcategory': 'Video Meditation',
                            'times_played': int(video_info.get('statistics', {}).get('viewCount', 0)),
                        }
                        meditations.append(meditation_data)
                
            except Exception as e:
                print(f"Error searching YouTube for '{query}': {e}")
                continue
        
        print(f"Found {len(meditations)} YouTube meditations")
        return meditations
    
    def search_spotify_meditations(self, queries: List[str], max_results_per_query: int = 50) -> List[Dict]:
        """Search for meditation content on Spotify"""
        if not self.spotify:
            print("Spotify API not configured")
            return []
        
        meditations = []
        
        for query in queries:
            try:
                print(f"Searching Spotify for: {query}")
                
                # Search for tracks
                results = self.spotify.search(q=query, type='track', limit=max_results_per_query)
                
                for track in results['tracks']['items']:
                    if track['duration_ms'] > 180000:  # At least 3 minutes
                        meditation_data = {
                            'name': track['name'][:200],
                            'type': self._categorize_spotify_meditation(track['name']),
                            'level': 'beginner',
                            'duration_minutes': track['duration_ms'] // 60000,
                            'description': f"Meditation track by {track['artists'][0]['name']}",
                            'instructions': self._generate_spotify_instructions(track['name']),
                            'benefits': ['Promotes relaxation', 'Reduces stress', 'Improves focus'],
                            'target_states': self._extract_target_states_spotify(track['name']),
                            'audio_url': track['external_urls'].get('spotify', ''),
                            'thumbnail_url': track['album']['images'][0]['url'] if track['album']['images'] else '',
                            'tags': [query],
                            'source': 'spotify',
                            'effectiveness_score': min(0.9, track['popularity'] / 100.0),
                            'instructor_name': track['artists'][0]['name'],
                            'subcategory': 'Audio Meditation',
                        }
                        meditations.append(meditation_data)
                        
                # Search for podcasts
                podcast_results = self.spotify.search(q=f"{query} meditation", type='show', limit=10)
                
                for show in podcast_results['shows']['items']:
                    episodes = self.spotify.show_episodes(show['id'], limit=20)
                    
                    for episode in episodes['items']:
                        if episode['duration_ms'] > 300000:  # At least 5 minutes
                            meditation_data = {
                                'name': f"{episode['name']} - {show['name']}"[:200],
                                'type': 'mindfulness',
                                'level': 'beginner',
                                'duration_minutes': episode['duration_ms'] // 60000,
                                'description': episode.get('description', '')[:500],
                                'instructions': ['Listen to this guided meditation podcast'],
                                'benefits': ['Guided meditation experience', 'Expert instruction', 'Varied content'],
                                'target_states': ['general_wellness', 'relaxation'],
                                'audio_url': episode['external_urls'].get('spotify', ''),
                                'thumbnail_url': episode['images'][0]['url'] if episode['images'] else '',
                                'tags': ['podcast', query],
                                'source': 'spotify_podcast',
                                'effectiveness_score': 0.8,
                                'instructor_name': show['publisher'],
                                'subcategory': 'Podcast Meditation',
                            }
                            meditations.append(meditation_data)
                
            except Exception as e:
                print(f"Error searching Spotify for '{query}': {e}")
                continue
        
        print(f"Found {len(meditations)} Spotify meditations")
        return meditations
    
    def aggregate_all_content(self) -> Dict[str, List[Dict]]:
        """Aggregate content from all sources"""
        print("Starting content aggregation...")
        
        # Define search queries for different meditation types
        meditation_queries = [
            'guided meditation',
            'mindfulness meditation',
            'breathing meditation',
            'body scan meditation',
            'sleep meditation',
            'anxiety meditation',
            'stress relief meditation',
            'loving kindness meditation',
            'zen meditation',
            'chakra meditation',
            'walking meditation',
            'mantra meditation'
        ]
        
        all_content = {
            'huggingface': self.load_huggingface_dataset(),
            'youtube': self.search_youtube_meditations(meditation_queries, max_results_per_query=25),
            'spotify': self.search_spotify_meditations(meditation_queries, max_results_per_query=25),
        }
        
        total_count = sum(len(content) for content in all_content.values())
        print(f"Total content aggregated: {total_count} meditations")
        
        return all_content
    
    # Helper methods
    def _map_meditation_type(self, style: str) -> str:
        """Map meditation style to our MeditationType enum"""
        style_mapping = {
            'guided meditation': 'mindfulness',
            'mindfulness': 'mindfulness',
            'breathing': 'breathing',
            'body scan': 'body_scan',
            'visualization': 'visualization',
            'loving kindness': 'loving_kindness',
            'mantra': 'mantra',
            'movement': 'movement',
        }
        return style_mapping.get(style.lower(), 'mindfulness')
    
    def _parse_duration(self, duration_str: str) -> int:
        """Parse duration string and return minutes"""
        if not duration_str:
            return 10
        
        # Extract numbers from duration string
        import re
        numbers = re.findall(r'\d+', duration_str)
        if numbers:
            return int(numbers[0])
        return 10
    
    def _parse_instructions(self, guidance: str) -> List[str]:
        """Parse meditation guidance into step-by-step instructions"""
        if not guidance:
            return ["Begin by finding a comfortable position", "Close your eyes and breathe naturally"]
        
        # Split by common sentence endings and clean up
        sentences = guidance.replace('. ', '.\n').split('\n')
        instructions = [s.strip() for s in sentences if s.strip() and len(s.strip()) > 10]
        
        return instructions[:10]  # Limit to 10 instructions
    
    def _extract_target_states(self, context: str) -> List[str]:
        """Extract target mental states from context"""
        state_keywords = {
            'stress': 'stress',
            'anxiety': 'anxiety',
            'depression': 'depression',
            'sleep': 'insomnia',
            'focus': 'focus',
            'anger': 'anger',
            'grief': 'grief',
            'healing': 'healing',
            'peace': 'peace',
            'calm': 'relaxation',
        }
        
        context_lower = context.lower()
        states = []
        
        for keyword, state in state_keywords.items():
            if keyword in context_lower:
                states.append(state)
        
        return states if states else ['general_wellness']
    
    def _parse_youtube_duration(self, duration: str) -> int:
        """Parse YouTube duration format (PT15M33S) to minutes"""
        import re
        
        # Extract minutes and seconds
        minutes_match = re.search(r'(\d+)M', duration)
        seconds_match = re.search(r'(\d+)S', duration)
        hours_match = re.search(r'(\d+)H', duration)
        
        total_minutes = 0
        
        if hours_match:
            total_minutes += int(hours_match.group(1)) * 60
        if minutes_match:
            total_minutes += int(minutes_match.group(1))
        if seconds_match:
            total_minutes += int(seconds_match.group(1)) // 60
        
        return max(1, total_minutes)  # At least 1 minute
    
    def _categorize_youtube_meditation(self, title: str, description: str) -> str:
        """Categorize YouTube meditation based on title and description"""
        text = (title + ' ' + description).lower()
        
        if any(word in text for word in ['breath', 'breathing']):
            return 'breathing'
        elif any(word in text for word in ['body scan', 'progressive']):
            return 'body_scan'
        elif any(word in text for word in ['loving kindness', 'compassion']):
            return 'loving_kindness'
        elif any(word in text for word in ['sleep', 'bedtime']):
            return 'body_scan'  # Often body scan for sleep
        elif any(word in text for word in ['walking', 'movement']):
            return 'movement'
        elif any(word in text for word in ['mantra', 'chant']):
            return 'mantra'
        elif any(word in text for word in ['chakra', 'energy']):
            return 'chakra'
        else:
            return 'mindfulness'
    
    def _generate_youtube_instructions(self, title: str) -> List[str]:
        """Generate basic instructions for YouTube meditation"""
        return [
            "Find a comfortable position",
            "Press play and follow along with the video",
            "Listen to the instructor's guidance",
            "Breathe naturally throughout the session",
            "If your mind wanders, gently return focus to the video",
            "Take your time transitioning back when finished"
        ]
    
    def _extract_benefits_from_description(self, description: str) -> List[str]:
        """Extract potential benefits from video description"""
        common_benefits = [
            'Reduces stress and anxiety',
            'Improves focus and concentration',
            'Promotes relaxation',
            'Enhances emotional well-being',
            'Improves sleep quality'
        ]
        
        description_lower = description.lower()
        benefits = []
        
        if 'stress' in description_lower:
            benefits.append('Reduces stress and tension')
        if 'anxiety' in description_lower:
            benefits.append('Calms anxiety and worry')
        if 'sleep' in description_lower:
            benefits.append('Improves sleep quality')
        if 'focus' in description_lower:
            benefits.append('Enhances concentration')
        if 'peace' in description_lower or 'calm' in description_lower:
            benefits.append('Promotes inner peace')
        
        return benefits if benefits else common_benefits[:3]
    
    def _extract_target_states_youtube(self, title: str, description: str) -> List[str]:
        """Extract target states from YouTube content"""
        text = (title + ' ' + description).lower()
        states = []
        
        state_mapping = {
            'stress': 'stress',
            'anxiety': 'anxiety',
            'depression': 'depression',
            'sleep': 'insomnia',
            'insomnia': 'insomnia',
            'anger': 'anger',
            'grief': 'grief',
            'focus': 'focus',
            'concentration': 'focus',
            'peace': 'peace',
            'calm': 'relaxation',
            'healing': 'healing',
        }
        
        for keyword, state in state_mapping.items():
            if keyword in text:
                states.append(state)
        
        return states if states else ['general_wellness']
    
    def _categorize_spotify_meditation(self, name: str) -> str:
        """Categorize Spotify meditation content"""
        name_lower = name.lower()
        
        if any(word in name_lower for word in ['breath', 'breathing']):
            return 'breathing'
        elif any(word in name_lower for word in ['body', 'scan']):
            return 'body_scan'
        elif any(word in name_lower for word in ['loving', 'kindness', 'compassion']):
            return 'loving_kindness'
        elif any(word in name_lower for word in ['sleep', 'bedtime', 'night']):
            return 'body_scan'
        elif any(word in name_lower for word in ['mantra', 'chant']):
            return 'mantra'
        elif any(word in name_lower for word in ['chakra', 'energy']):
            return 'chakra'
        else:
            return 'mindfulness'
    
    def _generate_spotify_instructions(self, name: str) -> List[str]:
        """Generate instructions for Spotify meditation"""
        return [
            "Find a quiet, comfortable space",
            "Put on headphones for best experience",
            "Close your eyes and listen to the audio",
            "Follow the guidance provided",
            "Allow yourself to relax completely",
            "Take a moment to reflect when finished"
        ]
    
    def _extract_target_states_spotify(self, name: str) -> List[str]:
        """Extract target states from Spotify content"""
        name_lower = name.lower()
        states = []
        
        if any(word in name_lower for word in ['stress', 'tension']):
            states.append('stress')
        if any(word in name_lower for word in ['anxiety', 'worry']):
            states.append('anxiety')
        if any(word in name_lower for word in ['sleep', 'bedtime']):
            states.append('insomnia')
        if any(word in name_lower for word in ['focus', 'concentration']):
            states.append('focus')
        if any(word in name_lower for word in ['calm', 'peace', 'relax']):
            states.append('relaxation')
        if any(word in name_lower for word in ['healing', 'recovery']):
            states.append('healing')
        
        return states if states else ['general_wellness']