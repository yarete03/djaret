from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Service


class HelloView(APIView):
    def get(self, request):
        name = Service.objects.values_list("name", flat=True).first() or "Lambda"
        return Response({"message": f"Hello from {name}"})
