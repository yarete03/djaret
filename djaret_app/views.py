from django.views.generic import TemplateView
from rest_framework.views import APIView
from rest_framework.response import Response


class IndexView(TemplateView):
    template_name = "index.html"


class HelloView(APIView):
    def get(self, request):
        return Response({"message": "Hello from Lambda"})
