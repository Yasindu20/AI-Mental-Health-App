from django.core.management.base import BaseCommand
from django.db import transaction
from meditation.models import Meditation

class Command(BaseCommand):
    help = 'Fix external_id field by converting empty strings to NULL'
    
    def handle(self, *args, **options):
        with transaction.atomic():
            # Update all meditations with empty external_id to NULL
            updated = Meditation.objects.filter(external_id='').update(external_id=None)
            
            self.stdout.write(
                self.style.SUCCESS(
                    f'Successfully updated {updated} meditation records, '
                    f'converting empty external_id to NULL'
                )
            )
            
            # Show summary
            total_meditations = Meditation.objects.count()
            null_external_ids = Meditation.objects.filter(external_id__isnull=True).count()
            
            self.stdout.write(f'Total meditations: {total_meditations}')
            self.stdout.write(f'Meditations with NULL external_id: {null_external_ids}')
            self.stdout.write(f'Meditations with external_id: {total_meditations - null_external_ids}')
