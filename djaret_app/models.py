from django.db import models


class Service(models.Model):
    name = models.CharField(max_length=255)

    class Meta:
        managed = False
        db_table = "djaret_app_service"

    def __str__(self):
        return self.name
