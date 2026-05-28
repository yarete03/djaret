import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "Idempotently create or update a Django admin account from env vars."

    def handle(self, *args, **options):
        name = os.environ.get("ADMIN_USERNAME")
        mail = os.environ.get("ADMIN_EMAIL", "")
        secret = os.environ.get("ADMIN_SECRET")

        if not name or not secret:
            raise CommandError("ADMIN_USERNAME and ADMIN_SECRET must be set")

        User = get_user_model()
        account, created = User.objects.get_or_create(
            username=name,
            defaults={"email": mail, "is_staff": True, "is_superuser": True},
        )
        account.is_staff = True
        account.is_superuser = True
        if mail:
            account.email = mail
        account.set_password(secret)
        account.save()

        action = "created" if created else "updated"
        self.stdout.write(self.style.SUCCESS(f"{action} admin: {name}"))