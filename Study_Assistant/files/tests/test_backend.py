import sys
from pathlib import Path
import unittest

root_dir = Path(r'c:\Users\jaswa\EDUSTREAK\Study_Assistant\files')
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from fastapi.testclient import TestClient
from backend.main import app, chunk_text, truncate_context

class TestBackendEndpoints(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)

    def test_routes_registered(self):
        routes = [route.path for route in app.routes]
        expected_routes = [
            '/upload/',
            '/query/',
            '/summary/',
            '/quiz/',
            '/quiz/interactive/',
            '/chat/',
            '/school-insights/chat/',
            '/skill-coach/recommendations/',
            '/teacher-hub/lesson-plan/',
            '/teacher-hub/question-generator/',
            '/teacher-hub/worksheet/',
            '/teacher-hub/assistant-chat/',
        ]
        for route in expected_routes:
            self.assertIn(route, routes, f'Route {route} not registered in app')

    def test_chunk_text(self):
        text = 'EduStreak provides an intelligent learning platform for modern schools. ' * 50
        chunks = chunk_text(text, chunk_size=500, chunk_overlap=100)
        self.assertGreater(len(chunks), 1)
        for chunk in chunks:
            self.assertLessEqual(len(chunk), 600)

    def test_truncate_context(self):
        short_text = 'Short context'
        self.assertEqual(truncate_context(short_text, max_chars=100), short_text)

        long_text = 'A' * 500
        truncated = truncate_context(long_text, max_chars=100)
        self.assertTrue('[Context truncated' in truncated)
        self.assertTrue(truncated.startswith('A' * 100))

    def test_teacher_hub_lesson_plan(self):
        payload = {
            'grade_or_class': 'Class 8',
            'subject': 'Science',
            'chapter': 'Light',
            'topic': 'Reflection and Refraction',
            'duration_minutes': 45,
            'learning_objectives': ['Understand laws of reflection']
        }
        response = self.client.post('/teacher-hub/lesson-plan/', json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn('lesson_title', data)
        self.assertIn('objectives', data)
        self.assertIn('teaching_explanation', data)
        self.assertIn('learning_outcomes', data)

    def test_teacher_hub_question_generator(self):
        payload = {
            'grade_or_class': 'Class 9',
            'subject': 'Mathematics',
            'chapter': 'Polynomials',
            'topic': 'Factorization of Quadratic Polynomials',
            'difficulty': 'Medium',
            'question_type': 'mcq',
            'num_questions': 3,
            'total_marks': 15
        }
        response = self.client.post('/teacher-hub/question-generator/', json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn('questions', data)
        self.assertEqual(len(data['questions']), 3)

    def test_teacher_hub_worksheet(self):
        payload = {
            'grade_or_class': 'Class 7',
            'subject': 'Social Studies',
            'chapter': 'Our Environment',
            'topic': 'Atmosphere and Climate',
            'total_marks': 25
        }
        response = self.client.post('/teacher-hub/worksheet/', json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn('title', data)
        self.assertIn('sections', data)

    def test_teacher_hub_assistant_chat(self):
        payload = {
            'question': 'Suggest an interactive hook for teaching photosynthesis to Class 7 students.',
            'grade_or_class': 'Class 7',
            'subject': 'Science',
        }
        response = self.client.post('/teacher-hub/assistant-chat/', json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn('answer', data)
        self.assertIn('pedagogy_tips', data)
        self.assertIn('suggested_followups', data)
        self.assertTrue(len(data['answer']) > 0)

    def test_skill_coach_recommendations(self):
        payload = {
            'student_id': 'std_101',
            'student_name': 'Rohan Sharma',
            'skill_scores': {'Problem Solving': 45.0, 'Critical Thinking': 52.0},
            'weakest_skills': ['Problem Solving'],
            'strongest_skills': ['Consistency and Discipline'],
            'assessed_topics': ['Linear Equations'],
            'question': 'How can I improve my algebra problem solving?'
        }
        response = self.client.post('/skill-coach/recommendations/', json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn('summary', data)
        self.assertIn('recommendations', data)
        self.assertIn('action_plan', data)
        self.assertEqual(data['student_id'], 'std_101')

if __name__ == '__main__':
    unittest.main()
