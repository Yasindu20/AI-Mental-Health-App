import torch
from transformers import (
    AutoTokenizer, 
    AutoModelForCausalLM, 
    BitsAndBytesConfig,
    pipeline
)
import logging
from typing import Dict, Optional
import json

logger = logging.getLogger(__name__)

class LlamaService:
    """Service for handling Llama 3.2 interactions"""
    
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.pipeline = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model_loaded = False
        
    def load_model(self):
        """Load Llama 3.2 with 4-bit quantization for 16GB RAM"""
        if self.model_loaded:
            return
            
        try:
            model_id = "meta-llama/Llama-3.2-3B-Instruct"  # Using 3B model for 16GB RAM
            
            # Configure 4-bit quantization
            bnb_config = BitsAndBytesConfig(
                load_in_4bit=True,
                bnb_4bit_quant_type="nf4",
                bnb_4bit_compute_dtype=torch.float16,
                bnb_4bit_use_double_quant=True,
            )
            
            # Load tokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(model_id)
            
            # Load model with quantization
            self.model = AutoModelForCausalLM.from_pretrained(
                model_id,
                quantization_config=bnb_config,
                device_map="auto",
                trust_remote_code=True,
            )
            
            # Create pipeline
            self.pipeline = pipeline(
                "text-generation",
                model=self.model,
                tokenizer=self.tokenizer,
                device_map="auto",
            )
            
            self.model_loaded = True
            logger.info("Llama 3.2 model loaded successfully")
            
        except Exception as e:
            logger.error(f"Error loading model: {str(e)}")
            raise
    
    def generate_meditation_response(
        self, 
        message: str, 
        context: Optional[Dict] = None,
        user_mood: Optional[str] = None
    ) -> Dict:
        """Generate meditation-focused response"""
        
        if not self.model_loaded:
            self.load_model()
        
        # Create system prompt for meditation focus
        system_prompt = """You are a compassionate meditation and mindfulness coach. 
        Your role is to:
        1. Listen empathetically to users' feelings and experiences
        2. Guide them through meditation and mindfulness practices
        3. Offer gentle wisdom and support for mental wellness
        4. Suggest appropriate meditation techniques based on their current state
        5. Keep responses warm, supportive, and focused on present-moment awareness
        
        Always maintain a calm, peaceful tone and avoid medical advice."""
        
        # Build context-aware prompt
        user_context = ""
        if context and user_mood:
            user_context = f"\nUser's current mood: {user_mood}"
            if context.get('recent_topics'):
                user_context += f"\nRecent concerns: {', '.join(context['recent_topics'])}"
        
        # Construct full prompt
        full_prompt = f"""<|begin_of_text|><|start_header_id|>system<|end_header_id|>
{system_prompt}{user_context}<|eot_id|>
<|start_header_id|>user<|end_header_id|>
{message}<|eot_id|>
<|start_header_id|>assistant<|end_header_id|>"""
        
        # Generate response
        try:
            outputs = self.pipeline(
                full_prompt,
                max_new_tokens=300,
                temperature=0.7,
                top_p=0.9,
                do_sample=True,
                pad_token_id=self.tokenizer.eos_token_id,
            )
            
            response_text = outputs[0]['generated_text']
            # Extract only the assistant's response
            response_text = response_text.split("<|start_header_id|>assistant<|end_header_id|>")[-1]
            response_text = response_text.replace("<|eot_id|>", "").strip()
            
            # Analyze response for meditation suggestions
            meditation_suggested = any(
                keyword in response_text.lower() 
                for keyword in ['breathe', 'meditation', 'mindfulness', 'relax', 'calm']
            )
            
            return {
                'response': response_text,
                'meditation_suggested': meditation_suggested,
                'techniques': self._extract_techniques(response_text),
            }
            
        except Exception as e:
            logger.error(f"Error generating response: {str(e)}")
            return {
                'response': "I'm here to support you. Let's take a moment to breathe together. "
                           "Would you like to try a simple breathing exercise?",
                'meditation_suggested': True,
                'techniques': ['breathing'],
            }
    
    def _extract_techniques(self, response: str) -> list:
        """Extract meditation techniques mentioned in response"""
        techniques = []
        technique_keywords = {
            'breathing': ['breath', 'breathing', 'inhale', 'exhale'],
            'body_scan': ['body scan', 'tension', 'relax your body'],
            'mindfulness': ['mindful', 'present moment', 'awareness'],
            'visualization': ['imagine', 'visualize', 'picture'],
            'loving_kindness': ['loving', 'kindness', 'compassion'],
        }
        
        response_lower = response.lower()
        for technique, keywords in technique_keywords.items():
            if any(keyword in response_lower for keyword in keywords):
                techniques.append(technique)
                
        return techniques

# Singleton instance
llama_service = LlamaService()