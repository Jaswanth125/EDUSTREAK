import sys
from pathlib import Path
import unittest

root_dir = Path(r'c:\Users\jaswa\EDUSTREAK\Study_Assistant\files')
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from fastapi.testclient import TestClient
from backend.main import app
from services.email_service import EmailService

class TestEmailEndpoints(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)
        cls.email_service = EmailService()

    def test_invitation_routes_registered(self):
        routes = [route.path for route in app.routes]
        self.assertIn('/api/v1/invitations/send-email', routes)
        self.assertIn('/api/v1/invitations/resend-email', routes)

    def test_html_template_generation(self):
        html = self.email_service.generate_invitation_html(
            principal_name="Dr. Sudhir Sharma",
            school_name="Z.P. High School, Kankipadu",
            school_code="AP-KRI-042",
            invitation_code="INV-PRIN-APKRI042-8821",
            invitation_token="test_token_12345",
        )
        self.assertIn("EDUSTREAK", html)
        self.assertIn("Dr. Sudhir Sharma", html)
        self.assertIn("Z.P. High School, Kankipadu", html)
        self.assertIn("AP-KRI-042", html)
        self.assertIn("INV-PRIN-APKRI042-8821", html)
        self.assertIn("Activate Principal Account", html)

    def test_send_invitation_email_endpoint_success(self):
        payload = {
            "principal_email": "principal.test@edustreak.ap.gov.in",
            "principal_name": "K. Srinivas Rao",
            "school_name": "Sri Venkateswara Vidya Mandir",
            "school_code": "AP-KRI-SVVM",
            "invitation_code": "INV-PRIN-APKRI-SVVM-7741",
            "invitation_token": "sec_tok_9918237123",
        }
        response = self.client.post("/api/v1/invitations/send-email", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertTrue(data["success"])
        self.assertEqual(data["status"], "sent")
        self.assertEqual(data["recipient"], "principal.test@edustreak.ap.gov.in")
        self.assertIsNotNone(data["messageId"])

    def test_resend_invitation_email_endpoint_success(self):
        payload = {
            "principal_email": "principal.test@edustreak.ap.gov.in",
            "principal_name": "K. Srinivas Rao",
            "school_name": "Sri Venkateswara Vidya Mandir",
            "school_code": "AP-KRI-SVVM",
            "invitation_code": "INV-PRIN-APKRI-SVVM-7741",
            "invitation_token": "sec_tok_9918237123",
        }
        response = self.client.post("/api/v1/invitations/resend-email", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertTrue(data["success"])

    def test_send_invitation_validation_error(self):
        payload = {
            "principal_email": "invalid-email",
            "principal_name": "Test",
            "school_name": "Test School",
            "school_code": "SCH-001",
            "invitation_code": "INV-001",
        }
        response = self.client.post("/api/v1/invitations/send-email", json=payload)
        self.assertEqual(response.status_code, 400)

if __name__ == '__main__':
    unittest.main()
