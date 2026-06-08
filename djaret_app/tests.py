from unittest.mock import patch

from django.test import SimpleTestCase
from rest_framework.test import APIRequestFactory

from djaret_app.views import HelloView


class HelloViewTests(SimpleTestCase):
    """The Service model is managed=False (no test table) and CI has no MySQL,
    so we mock the query and keep these DB-free via SimpleTestCase."""

    def setUp(self):
        self.factory = APIRequestFactory()

    @patch("djaret_app.views.Service")
    def test_returns_service_name(self, mock_service):
        mock_service.objects.values_list.return_value.first.return_value = "RDS"
        response = HelloView.as_view()(self.factory.get("/api/hello/"))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, {"message": "Hello from RDS"})

    @patch("djaret_app.views.Service")
    def test_falls_back_to_lambda(self, mock_service):
        mock_service.objects.values_list.return_value.first.return_value = None
        response = HelloView.as_view()(self.factory.get("/api/hello/"))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, {"message": "Hello from Lambda"})
