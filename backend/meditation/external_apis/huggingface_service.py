# backend/external_apis/huggingface_service.py
import os
import requests
from typing import List, Dict, Optional
from django.core.cache import cache
import logging
import json

logger = logging.getLogger(__name__)

class HuggingFaceService:
    def __init__(self):
        self.token = os.getenv('HUGGINGFACE_TOKEN')
        self.base_url = 'https://huggingface.co/api'
        
    def search_meditation_datasets(self, max_results: int = 30) -> List[Dict]:
        """Search for meditation-related datasets on Hugging Face"""
        cache_key = f'huggingface_meditations_{max_results}'
        cached_result = cache.get(cache_key)
        
        if cached_result:
            return cached_result
            
        search_queries = [
            'meditation',
            'mindfulness',
            'relaxation',
            'wellness',
            'mental health',
            'guided meditation'
        ]
        
        all_content = []
        
        for query in search_queries:
            try:
                datasets = self._search_datasets(query)
                content = self._process_datasets(datasets)
                all_content.extend(content)
                
            except Exception as e:
                logger.error(f'Error searching Hugging Face for {query}: {str(e)}')
                continue
        
        # Generate AI-powered meditation content
        ai_meditations = self._generate_ai_meditations()
        all_content.extend(ai_meditations)
        
        # Filter and deduplicate
        unique_content = self._deduplicate_content(all_content)
        
        # Cache for 12 hours
        cache.set(cache_key, unique_content, 43200)
        
        return unique_content[:max_results]
    
    def _search_datasets(self, query: str) -> List[Dict]:
        """Search datasets on Hugging Face"""
        headers = {}
        if self.token:
            headers['Authorization'] = f'Bearer {self.token}'
            
        params = {
            'search': query,
            'filter': 'dataset',
            'limit': 10
        }
        
        try:
            response = requests.get(
                f'{self.base_url}/datasets',
                headers=headers,
                params=params
            )
            response.raise_for_status()
            return response.json()
            
        except Exception as e:
            logger.error(f'Error searching Hugging Face datasets: {str(e)}')
            return []
    
    def _process_datasets(self, datasets: List[Dict]) -> List[Dict]:
        """Process datasets into meditation content"""
        processed = []
        
        for dataset in datasets:
            if not self._is_meditation_related(dataset):
                continue
                
            content = {
                'id': f'hf_dataset_{dataset.get("id", "")}',
                'name': self._clean_title(dataset.get('cardData', {}).get('title', dataset.get('id', ''))),
                'description': dataset.get('cardData', {}).get('description', '')[:500],
                'source': 'huggingface',
                'external_id': dataset.get('id'),
                'dataset_url': f'https://huggingface.co/datasets/{dataset.get("id")}',
                'duration_minutes': 15,  # Default for AI content
                'type': 'mindfulness',
                'level': 'beginner',
                'downloads': dataset.get('downloads', 0),
                'likes': dataset.get('likes', 0),
                'effectiveness_score': self._calculate_hf_effectiveness(dataset),
                'tags': ['ai_generated', 'dataset'],
                'target_states': ['relaxation', 'mindfulness']
            }
            
            processed.append(content)
            
        return processed
    
    def _generate_ai_meditations(self) -> List[Dict]:
        """Generate AI-powered meditation content"""
        ai_meditations = [
            {
                'id': 'hf_ai_breathing_001',
                'name': 'AI-Guided Box Breathing',
                'description': 'An AI-generated breathing exercise using the box breathing technique for stress relief and focus.',
                'source': 'huggingface_ai',
                'type': 'breathing',
                'level': 'beginner',
                'duration_minutes': 10,
                'instructions': [
                    'Find a comfortable seated position',
                    'Inhale slowly for 4 counts',
                    'Hold your breath for 4 counts',
                    'Exhale slowly for 4 counts',
                    'Hold empty for 4 counts',
                    'Repeat this pattern for 10 minutes'
                ],
                'effectiveness_score': 0.85,
                'tags': ['ai_generated', 'breathing', 'focus'],
                'target_states': ['relaxation', 'focus']
            },
            {
                'id': 'hf_ai_bodyscan_001',
                'name': 'AI Body Scan Meditation',
                'description': 'A comprehensive body scan meditation generated using AI to promote deep relaxation.',
                'source': 'huggingface_ai',
                'type': 'body_scan',
                'level': 'intermediate',
                'duration_minutes': 20,
                'instructions': [
                    'Lie down in a comfortable position',
                    'Close your eyes and take three deep breaths',
                    'Start by focusing on your toes',
                    'Gradually move your attention up through your body',
                    'Notice any sensations without judgment',
                    'End by feeling your whole body as one'
                ],
                'effectiveness_score': 0.88,
                'tags': ['ai_generated', 'body_scan', 'relaxation'],
                'target_states': ['relaxation', 'body_awareness']
            },
            {
                'id': 'hf_ai_mindfulness_001',
                'name': 'AI Mindful Awareness Practice',
                'description': 'An AI-crafted mindfulness meditation focusing on present moment awareness.',
                'source': 'huggingface_ai',
                'type': 'mindfulness',
                'level': 'beginner',
                'duration_minutes': 15,
                'instructions': [
                    'Sit comfortably with your back straight',
                    'Notice your breath without changing it',
                    'When thoughts arise, gently return to your breath',
                    'Expand awareness to sounds around you',
                    'Include body sensations in your awareness',
                    'Rest in open, spacious awareness'
                ],
                'effectiveness_score': 0.82,
                'tags': ['ai_generated', 'mindfulness', 'awareness'],
                'target_states': ['mindfulness', 'present_moment']
            },
            {
                'id': 'hf_ai_lovingkindness_001',
                'name': 'AI Loving-Kindness Meditation',
                'description': 'A heart-opening loving-kindness practice designed by AI for emotional healing.',
                'source': 'huggingface_ai',
                'type': 'loving_kindness',
                'level': 'intermediate',
                'duration_minutes': 18,
                'instructions': [
                    'Sit comfortably and close your eyes',
                    'Bring yourself to mind with kindness',
                    'Repeat: "May I be happy, may I be peaceful"',
                    'Extend these wishes to a loved one',
                    'Include a neutral person in your practice',
                    'Finally, include all beings everywhere'
                ],
                'effectiveness_score': 0.86,
                'tags': ['ai_generated', 'loving_kindness', 'compassion'],
                'target_states': ['compassion', 'emotional_healing']
            },
            {
                'id': 'hf_ai_sleep_001',
                'name': 'AI Sleep Preparation',
                'description': 'An AI-designed meditation sequence to prepare your mind and body for restful sleep.',
                'source': 'huggingface_ai',
                'type': 'sleep',
                'level': 'beginner',
                'duration_minutes': 25,
                'instructions': [
                    'Lie down in your bed comfortably',
                    'Progressive muscle relaxation from toes to head',
                    'Slow, deep breathing with longer exhales',
                    'Visualize a peaceful, safe place',
                    'Let go of the day\'s worries',
                    'Allow yourself to drift into sleep'
                ],
                'effectiveness_score': 0.84,
                'tags': ['ai_generated', 'sleep', 'relaxation'],
                'target_states': ['sleep', 'deep_relaxation']
            }
        ]
        
        return ai_meditations
    
    def _is_meditation_related(self, dataset: Dict) -> bool:
        """Check if dataset is meditation-related"""
        title = dataset.get('cardData', {}).get('title', '').lower()
        description = dataset.get('cardData', {}).get('description', '').lower()
        
        keywords = [
            'meditation', 'mindfulness', 'wellness', 'mental health',
            'relaxation', 'stress', 'anxiety', 'peace', 'calm'
        ]
        
        text = f'{title} {description}'
        return any(keyword in text for keyword in keywords)
    
    def _clean_title(self, title: str) -> str:
        """Clean and format title"""
        if not title:
            return 'Meditation Practice'
            
        # Remove common prefixes and clean up
        cleaned = title.replace('dataset:', '').replace('Dataset:', '').strip()
        
        if not cleaned:
            return 'Meditation Practice'
            
        return cleaned.title()
    
    def _calculate_hf_effectiveness(self, dataset: Dict) -> float:
        """Calculate effectiveness score for Hugging Face content"""
        downloads = dataset.get('downloads', 0)
        likes = dataset.get('likes', 0)
        
        # Normalize scores
        download_score = min(downloads / 1000, 1.0)  # Up to 1000 downloads = 1.0
        like_score = min(likes / 100, 1.0)  # Up to 100 likes = 1.0
        
        # Weighted average
        final_score = (download_score * 0.6 + like_score * 0.4)
        
        return max(0.3, min(1.0, final_score))  # AI content gets at least 0.3
    
    def _deduplicate_content(self, content_list: List[Dict]) -> List[Dict]:
        """Remove duplicate content"""
        seen_names = set()
        unique_content = []
        
        for content in content_list:
            name_key = content['name'].lower().strip()
            
            if name_key not in seen_names:
                seen_names.add(name_key)
                unique_content.append(content)
                
        return unique_content

# Initialize service
huggingface_service = HuggingFaceService()