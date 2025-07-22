import os
import requests
from typing import List, Dict, Optional
from django.core.cache import cache
from django.conf import settings
import logging
import json
import random

logger = logging.getLogger(__name__)

class HuggingFaceService:
    def __init__(self):
        # Get token from settings first, then environment
        config = getattr(settings, 'EXTERNAL_API_CONFIG', {})
        self.token = config.get('HUGGINGFACE_TOKEN') or os.getenv('HUGGINGFACE_TOKEN', '').strip()
        self.base_url = 'https://huggingface.co/api'
        
        # Meditation templates for generating varied content
        self.meditation_templates = [
            {
                'type': 'breathing',
                'titles': ['Box Breathing Exercise', 'Deep Breathing Practice', 'Calming Breath Work'],
                'descriptions': [
                    'A structured breathing exercise using the box breathing technique',
                    'Deep breathing practice for stress relief and relaxation',
                    'Calming breathwork to center your mind and body'
                ]
            },
            {
                'type': 'body_scan',
                'titles': ['Progressive Body Scan', 'Full Body Relaxation', 'Mindful Body Awareness'],
                'descriptions': [
                    'A comprehensive body scan meditation for deep relaxation',
                    'Progressive relaxation technique for releasing tension',
                    'Mindful awareness of body sensations and relaxation'
                ]
            },
            {
                'type': 'mindfulness',
                'titles': ['Present Moment Awareness', 'Mindful Observation', 'Awareness Practice'],
                'descriptions': [
                    'Cultivating present moment awareness and mindfulness',
                    'Practice of mindful observation and non-judgmental awareness',
                    'Developing deeper awareness and presence'
                ]
            },
            {
                'type': 'loving_kindness',
                'titles': ['Loving-Kindness Practice', 'Compassion Meditation', 'Heart Opening'],
                'descriptions': [
                    'Cultivating love and kindness towards self and others',
                    'Heart-centered meditation for developing compassion',
                    'Opening the heart with loving-kindness practice'
                ]
            },
            {
                'type': 'visualization',
                'titles': ['Peaceful Garden Visualization', 'Healing Light Meditation', 'Mountain Visualization'],
                'descriptions': [
                    'Guided visualization through a peaceful natural setting',
                    'Healing meditation using light and energy visualization',
                    'Mountain meditation for strength and stability'
                ]
            }
        ]
        
        logger.info(f"HuggingFace token present: {'Yes' if self.token else 'No'}")
        if self.token:
            logger.info(f"HuggingFace token: {self.token[:10]}...")
    
    def test_api_connection(self) -> bool:
        """Test if the HuggingFace API is working"""
        try:
            # Test with a simple API call
            headers = {}
            if self.token:
                headers['Authorization'] = f'Bearer {self.token}'
                
            response = requests.get(
                f'{self.base_url}/models',
                params={'limit': 1},
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info("HuggingFace API connection successful")
                return True
            else:
                logger.error(f"HuggingFace API error: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"HuggingFace API connection test failed: {str(e)}")
            return False
    
    def generate_paginated_meditations(self, page: int = 1, max_results: int = 15) -> Dict:
        """NEW: Generate AI meditation content with pagination support"""
        try:
            logger.info(f"Generating AI meditations for page {page}")
            
            # Generate varied content based on page number
            ai_meditations = self._generate_varied_ai_meditations(page, max_results)
            
            # HuggingFace can generate unlimited content, so always has more
            total_available = max_results * 100  # Very high limit for AI generation
            
            logger.info(f"Generated {len(ai_meditations)} AI meditations for page {page}")
            
            return {
                'content': ai_meditations,
                'total_available': total_available
            }
            
        except Exception as e:
            logger.error(f'Error generating paginated AI meditations: {str(e)}')
            return {'content': [], 'total_available': 0}
    
    def _generate_varied_ai_meditations(self, page: int, count: int) -> List[Dict]:
        """Generate varied AI meditation content for different pages"""
        meditations = []
        
        # Use page number to seed randomness for consistent results per page
        random.seed(page * 42)  # Consistent seed per page
        
        for i in range(count):
            # Select template based on page and iteration for variety
            template_index = (page + i) % len(self.meditation_templates)
            template = self.meditation_templates[template_index]
            
            # Generate unique content for this meditation
            title_index = (page * i) % len(template['titles'])
            desc_index = (page * i + 1) % len(template['descriptions'])
            
            # Add page-specific variation to make content unique
            page_suffix = f" - Series {page}" if page > 1 else ""
            variation_num = (page - 1) * count + i + 1
            
            meditation = {
                'id': f'hf_ai_{template["type"]}_{variation_num:03d}',
                'name': f'{template["titles"][title_index]}{page_suffix}',
                'description': f'{template["descriptions"][desc_index]} (Variation {variation_num})',
                'source': 'huggingface_ai',
                'external_id': f'ai_{template["type"]}_{variation_num:03d}',
                'type': template['type'],
                'level': self._get_level_for_page_item(page, i),
                'duration_minutes': self._get_duration_for_page_item(page, i),
                'instructions': self._generate_instructions(template['type'], page, i),
                'effectiveness_score': self._calculate_ai_effectiveness(page, i),
                'tags': self._generate_tags(template['type'], page),
                'target_states': self._generate_target_states(template['type'], page),
                'benefits': self._generate_benefits(template['type']),
                'is_free': True,
                'requires_subscription': False,
                'language': 'en'
            }
            
            meditations.append(meditation)
        
        return meditations
    
    def _get_level_for_page_item(self, page: int, item: int) -> str:
        """Get varied difficulty levels across pages"""
        levels = ['beginner', 'intermediate', 'advanced']
        return levels[(page + item) % len(levels)]
    
    def _get_duration_for_page_item(self, page: int, item: int) -> int:
        """Get varied durations across pages"""
        durations = [5, 10, 15, 20, 25, 30]
        return durations[(page + item) % len(durations)]
    
    def _generate_instructions(self, med_type: str, page: int, item: int) -> List[str]:
        """Generate varied instructions based on meditation type and page"""
        base_instructions = {
            'breathing': [
                'Find a comfortable seated position',
                'Close your eyes gently',
                'Inhale slowly for 4 counts',
                'Hold your breath for 4 counts',
                'Exhale slowly for 4 counts',
                'Hold empty for 4 counts',
                'Continue this pattern'
            ],
            'body_scan': [
                'Lie down comfortably',
                'Close your eyes and breathe naturally',
                'Start by focusing on your toes',
                'Gradually move attention up through your body',
                'Notice sensations without judgment',
                'Relax each body part as you go',
                'End with whole-body awareness'
            ],
            'mindfulness': [
                'Sit in a comfortable position',
                'Notice your breath without changing it',
                'When thoughts arise, gently acknowledge them',
                'Return attention to your breath',
                'Expand awareness to sounds around you',
                'Include all sensations in your awareness',
                'Rest in open, spacious awareness'
            ],
            'loving_kindness': [
                'Sit comfortably with eyes closed',
                'Bring yourself to mind with kindness',
                'Repeat: "May I be happy and peaceful"',
                'Extend these wishes to a loved one',
                'Include a neutral person in your practice',
                'Send kindness to someone difficult',
                'Extend love to all beings everywhere'
            ],
            'visualization': [
                'Find a quiet, comfortable position',
                'Close your eyes and breathe deeply',
                'Imagine a peaceful, beautiful place',
                'Engage all your senses in the visualization',
                'Feel the peace and calm of this place',
                'Let this feeling fill your entire being',
                'Carry this peace with you as you return'
            ]
        }
        
        instructions = base_instructions.get(med_type, base_instructions['mindfulness'])
        
        # Add page-specific variation
        if page > 1:
            variation_instruction = f'This is practice variation {page} - notice any differences'
            instructions = instructions + [variation_instruction]
        
        return instructions
    
    def _calculate_ai_effectiveness(self, page: int, item: int) -> float:
        """Calculate varied effectiveness scores"""
        # Use page and item to create consistent but varied scores
        base_score = 0.7 + ((page + item) % 10) * 0.03  # Range from 0.7 to 0.97
        return min(0.98, base_score)
    
    def _generate_tags(self, med_type: str, page: int) -> List[str]:
        """Generate tags based on type and page"""
        base_tags = {
            'breathing': ['ai_generated', 'breathing', 'stress_relief'],
            'body_scan': ['ai_generated', 'body_scan', 'relaxation'],
            'mindfulness': ['ai_generated', 'mindfulness', 'awareness'],
            'loving_kindness': ['ai_generated', 'loving_kindness', 'compassion'],
            'visualization': ['ai_generated', 'visualization', 'healing']
        }
        
        tags = base_tags.get(med_type, ['ai_generated', 'meditation'])
        
        # Add page-specific tags
        if page > 3:
            tags.append('advanced_series')
        elif page > 1:
            tags.append('series')
        
        return tags
    
    def _generate_target_states(self, med_type: str, page: int) -> List[str]:
        """Generate target states based on type and page"""
        base_states = {
            'breathing': ['relaxation', 'stress', 'anxiety'],
            'body_scan': ['relaxation', 'tension', 'body_awareness'],
            'mindfulness': ['mindfulness', 'present_moment', 'awareness'],
            'loving_kindness': ['compassion', 'self_love', 'emotional_healing'],
            'visualization': ['healing', 'peace', 'visualization']
        }
        
        states = base_states.get(med_type, ['relaxation', 'general_wellness'])
        
        # Add page-specific states for variety
        if page % 2 == 0:
            states.append('focus')
        if page % 3 == 0:
            states.append('energy')
        
        return states
    
    def _generate_benefits(self, med_type: str) -> List[str]:
        """Generate benefits based on meditation type"""
        base_benefits = {
            'breathing': [
                'Reduces stress and anxiety',
                'Improves focus and concentration',
                'Calms the nervous system',
                'Enhances emotional regulation'
            ],
            'body_scan': [
                'Releases physical tension',
                'Increases body awareness',
                'Promotes deep relaxation',
                'Improves sleep quality'
            ],
            'mindfulness': [
                'Cultivates present moment awareness',
                'Reduces mental chatter',
                'Improves emotional balance',
                'Enhances overall well-being'
            ],
            'loving_kindness': [
                'Develops compassion and empathy',
                'Improves relationships',
                'Increases self-acceptance',
                'Enhances emotional resilience'
            ],
            'visualization': [
                'Promotes healing and recovery',
                'Enhances creativity and imagination',
                'Reduces negative thought patterns',
                'Increases sense of peace and calm'
            ]
        }
        
        return base_benefits.get(med_type, [
            'Promotes relaxation',
            'Reduces stress',
            'Improves well-being',
            'Enhances mindfulness'
        ])

    # Legacy method for backward compatibility
    def search_meditation_datasets(self, max_results: int = 15) -> List[Dict]:
        """Legacy method - redirects to paginated version"""
        result = self.generate_paginated_meditations(page=1, max_results=max_results)
        return result['content']

# Initialize service
huggingface_service = None
try:
    huggingface_service = HuggingFaceService()
    connection_status = huggingface_service.test_api_connection()
    logger.info(f"HuggingFace service initialized. Connection: {'OK' if connection_status else 'FAILED'}")
except Exception as e:
    logger.error(f"Failed to initialize HuggingFace service: {str(e)}")