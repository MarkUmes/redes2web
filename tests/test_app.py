import os
import unittest
from unittest.mock import patch
from main import app


class AppTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_home_is_available(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"pagina de prueba", response.data)
        self.assertIn(b"CI/CD en la nube AWS", response.data)

    def test_health_exposes_deployed_revision(self):
        with patch.dict(os.environ, {"BUILD_SHA": "a" * 40}):
            response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["status"], "ok")
        self.assertEqual(response.json["revision"], "a" * 40)

    def test_unknown_page_is_not_healthy(self):
        self.assertEqual(self.client.get("/not-found").status_code, 404)
