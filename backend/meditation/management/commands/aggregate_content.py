from django.core.management.base import BaseCommand
from django.db import transaction
from meditation.content_aggregator import ContentAggregator
from meditation.models import Meditation

class Command(BaseCommand):
    help = 'Aggregate meditation content from various sources'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--source',
            type=str,
            choices=['all', 'huggingface', 'youtube', 'spotify'],
            default='all',
            help='Specify which source to aggregate from'
        )
        parser.add_argument(
            '--limit',
            type=int,
            default=None,
            help='Limit number of meditations to import'
        )
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing meditations before importing'
        )
    
    def handle(self, *args, **options):
        aggregator = ContentAggregator()
        
        if options['clear']:
            self.stdout.write("Clearing existing meditations...")
            Meditation.objects.filter(source__in=['huggingface', 'youtube', 'spotify', 'spotify_podcast']).delete()
        
        # Aggregate content
        if options['source'] == 'all':
            all_content = aggregator.aggregate_all_content()
        else:
            if options['source'] == 'huggingface':
                content = aggregator.load_huggingface_dataset()
            elif options['source'] == 'youtube':
                queries = ['guided meditation', 'mindfulness meditation', 'breathing meditation']
                content = aggregator.search_youtube_meditations(queries)
            elif options['source'] == 'spotify':
                queries = ['meditation', 'mindfulness', 'relaxation']
                content = aggregator.search_spotify_meditations(queries)
            
            all_content = {options['source']: content}
        
        # Import to database
        total_imported = 0
        
        for source, meditations in all_content.items():
            self.stdout.write(f"Importing {len(meditations)} meditations from {source}...")
            
            imported_count = 0
            
            for meditation_data in meditations:
                if options['limit'] and total_imported >= options['limit']:
                    break
                
                try:
                    with transaction.atomic():
                        # Check if meditation already exists
                        if not Meditation.objects.filter(
                            name=meditation_data['name'],
                            source=meditation_data['source']
                        ).exists():
                            
                            meditation = Meditation.objects.create(**meditation_data)
                            imported_count += 1
                            total_imported += 1
                            
                            if imported_count % 100 == 0:
                                self.stdout.write(f"Imported {imported_count} from {source}...")
                
                except Exception as e:
                    self.stderr.write(f"Error importing meditation: {e}")
                    continue
            
            self.stdout.write(
                self.style.SUCCESS(f"Successfully imported {imported_count} meditations from {source}")
            )
        
        self.stdout.write(
            self.style.SUCCESS(f"Total imported: {total_imported} meditations")
        )