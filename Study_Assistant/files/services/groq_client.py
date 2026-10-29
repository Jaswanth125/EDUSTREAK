import os
import re
import json
import requests
from dotenv import load_dotenv

load_dotenv()


class GroqAPIException(Exception):
    """Raised when a Groq API call fails."""


class GroqClient:
    """
    A client for interacting with the Groq API.
    
    This class handles sending chat completion requests to the Groq API
    using an OpenAI-compatible endpoint with automatic model fallback.
    """
    def __init__(self, model=None):
        """
        Initializes the GroqClient.

        Args:
            model (str): Optional model name. Defaults to GROQ_MODEL env var or 'openai/gpt-oss-120b'.
        """
        self.api_key = os.getenv("GROQ_API_KEY")
        if not self.api_key:
            raise ValueError("GROQ_API_KEY environment variable not set.")
        
        self.model = model or os.getenv("GROQ_MODEL", "openai/gpt-oss-120b")
        self.api_url = "https://api.groq.com/openai/v1/chat/completions"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        print(f"Groq client initialized with model: {self.model}")

    def _call_groq_api(self, payload, timeout=60):
        """
        Calls the Groq API with automatic fallback if the requested model is unavailable.
        """
        candidate_models = [
            self.model,
            os.getenv("GROQ_MODEL", "openai/gpt-oss-120b"),
            "openai/gpt-oss-120b",
            "qwen/qwen3.8-27b",
            "openai/gpt-oss-20b",
        ]
        models_to_try = []
        for m in candidate_models:
            if m and m not in models_to_try:
                models_to_try.append(m)

        last_error = None
        for m in models_to_try:
            payload["model"] = m
            try:
                response = requests.post(self.api_url, headers=self.headers, json=payload, timeout=timeout)
                if response.status_code == 200:
                    result = response.json()
                    self.model = m
                    return result
                
                err_text = response.text
                try:
                    err_text = response.json().get('error', {}).get('message', response.text)
                except Exception:
                    pass
                
                last_error = f"Groq API error ({m}): {err_text}"
                if any(k in err_text.lower() for k in ["not exist", "access", "decommissioned", "not found"]):
                    print(f"Model {m} unavailable ({err_text}), trying next model...")
                    continue
                else:
                    raise GroqAPIException(f"Groq API error: {err_text}")
            except requests.exceptions.RequestException as e:
                last_error = f"Connection error: {str(e)}"
                print(f"Groq connection error with {m}: {e}, trying next...")
                continue

        raise GroqAPIException(last_error or "All Groq model attempts failed.")

    def get_answer(self, question, context):
        """
        Gets an answer from the Groq API based on a question and context.
        """
        system_prompt = (
            "You are a helpful assistant for a RAG system. "
            "Use the provided context to answer the user's question. "
            "If the context does not contain the answer, state that you don't know."
        )

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {question}"}
            ],
            "temperature": 0.7,
            "max_tokens": 1024,
        }

        try:
            result = self._call_groq_api(payload, timeout=60)
            if 'choices' in result and len(result['choices']) > 0:
                return result['choices'][0]['message']['content']
            return "Sorry, I received an unexpected response from the API."
        except GroqAPIException:
            raise
        except Exception as e:
            raise GroqAPIException(f"Error answering question: {str(e)}")
    
    def chat(self, message, conversation_history=None):
        """
        General chat with AI without document context.
        """
        system_prompt = "You are a helpful and friendly AI tutor for school students. Answer questions clearly and in simple language suitable for students."
        
        messages = [{"role": "system", "content": system_prompt}]
        if conversation_history:
            messages.extend(conversation_history)
        messages.append({"role": "user", "content": message})
        
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 1024,
        }
        
        try:
            result = self._call_groq_api(payload, timeout=60)
            if 'choices' in result and len(result['choices']) > 0:
                return result['choices'][0]['message']['content']
            raise GroqAPIException("Unexpected response format from API")
        except GroqAPIException:
            raise
        except Exception as e:
            raise GroqAPIException(f"Error in chat: {str(e)}")
    
    def generate_summary(self, topic, context):
        """
        Generate a summary for a specific topic based on context.
        """
        system_prompt = (
            "You are a helpful tutor creating summaries for school students. "
            "Create clear, well-structured summaries that are easy to understand. "
            "Use bullet points, headings, and simple language."
        )
        
        user_prompt = f"""Based on the following context from the study materials, create a comprehensive summary about "{topic}".

Context:
{context}

Please create a detailed summary covering:
1. Key concepts and definitions
2. Important points and examples
3. Any formulas or equations if applicable
4. Practical applications or real-world connections

Format the summary in a clear, student-friendly way with proper headings and bullet points."""

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": 0.5,
            "max_tokens": 1500,
        }
        
        try:
            result = self._call_groq_api(payload, timeout=90)
            if 'choices' in result and len(result['choices']) > 0:
                return result['choices'][0]['message']['content']
            raise GroqAPIException("Unexpected response format from API")
        except GroqAPIException:
            raise
        except Exception as e:
            raise GroqAPIException(f"Error generating summary: {str(e)}")
    
    def generate_quiz(self, topic, context, num_questions=5):
        """
        Generate a quiz for a specific topic.
        """
        system_prompt = (
            "You are a helpful tutor creating quizzes for school students. "
            "Create clear, educational questions with multiple choice options and explanations."
        )
        
        user_prompt = f"""Based on the following context from the study materials, create a quiz about "{topic}".

Context:
{context}

Please create {num_questions} quiz questions with:
1. Multiple choice questions (4 options each)
2. Clear and correct answers
3. Brief explanations for each answer

Format the quiz as:
Q1. [Question]
A) [Option 1]
B) [Option 2]
C) [Option 3]
D) [Option 4]

Answer: [Correct option] - [Explanation]

Repeat for all questions."""

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": 0.7,
            "max_tokens": 2000,
        }
        
        try:
            result = self._call_groq_api(payload, timeout=90)
            if 'choices' in result and len(result['choices']) > 0:
                return result['choices'][0]['message']['content']
            raise GroqAPIException("Unexpected response format from API")
        except GroqAPIException:
            raise
        except Exception as e:
            raise GroqAPIException(f"Error generating quiz: {str(e)}")
    
    def generate_structured_quiz(self, topic, context, num_questions=5):
        """
        Generate a structured quiz in JSON format for interactive use.
        """
        system_prompt = (
            "You are a helpful tutor creating quizzes for school students. "
            "You MUST respond with valid JSON only, no additional text."
        )
        
        user_prompt = f"""Based on the following context from the study materials, create a quiz about "{topic}".

Context:
{context}

Create {num_questions} multiple choice questions. Return ONLY a valid JSON object with this exact structure:
{{
  "questions": [
    {{
      "id": 1,
      "question": "Question text here",
      "options": {{
        "A": "Option A text",
        "B": "Option B text",
        "C": "Option C text",
        "D": "Option D text"
      }},
      "correct_answer": "A",
      "explanation": "Brief explanation of why this is correct"
    }}
  ]
}}

Return ONLY the JSON, no markdown, no code blocks, no additional text."""

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": 0.7,
            "max_tokens": 3000,
        }
        
        try:
            result = self._call_groq_api(payload, timeout=90)
            if 'choices' in result and len(result['choices']) > 0:
                content = result['choices'][0]['message']['content'].strip()
                
                # Remove markdown code blocks if present
                if content.startswith("```json"):
                    lines = content.split("\n")
                    content = "\n".join(lines[1:-1]) if len(lines) > 1 and lines[-1].startswith("```") else "\n".join(lines[1:])
                elif content.startswith("```"):
                    lines = content.split("\n")
                    content = "\n".join(lines[1:-1]) if len(lines) > 1 and lines[-1].startswith("```") else "\n".join(lines[1:])
                
                # Look for JSON object pattern
                json_match = re.search(r'\{.*"questions".*\}', content, re.DOTALL)
                if json_match:
                    content = json_match.group(0)
                
                # Parse JSON with fallback cleanup
                try:
                    quiz_data = json.loads(content)
                except json.JSONDecodeError:
                    content = re.sub(r',\s*}', '}', content)
                    content = re.sub(r',\s*]', ']', content)
                    quiz_data = json.loads(content)
                
                if not isinstance(quiz_data, dict) or "questions" not in quiz_data:
                    raise GroqAPIException("Invalid quiz structure: missing 'questions' key.")
                
                return quiz_data
            else:
                raise GroqAPIException("Unexpected response format from API")
        except GroqAPIException:
            raise
        except Exception as e:
            raise GroqAPIException(f"Error generating structured quiz: {str(e)}")
    
    def generate_full_document_summary(self, context):
        """
        Generate a comprehensive summary of all documents.
        """
        system_prompt = (
            "You are a helpful tutor creating comprehensive summaries for school students. "
            "Create clear, well-structured summaries that cover all major topics and concepts. "
            "Use bullet points, headings, and simple language. Organize the summary by topics/chapters."
        )
        
        user_prompt = f"""Based on the following study materials, create a comprehensive summary covering all the important topics and concepts.

Study Materials:
{context}

Please create a detailed summary that includes:
1. All major topics and chapters covered
2. Key concepts and definitions for each topic
3. Important points, examples, and explanations
4. Any formulas, equations, or important facts
5. Practical applications or real-world connections where applicable

Format the summary in a clear, student-friendly way with:
- Clear headings for each major topic/chapter
- Bullet points for key concepts
- Simple language suitable for students
- Logical organization of information"""

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": 0.5,
            "max_tokens": 2000,
        }
        
        try:
            result = self._call_groq_api(payload, timeout=90)
            if 'choices' in result and len(result['choices']) > 0:
                return result['choices'][0]['message']['content']
            raise GroqAPIException("Unexpected response format from API")
        except GroqAPIException:
            raise
        except Exception as e:
            raise GroqAPIException(f"Error generating full document summary: {str(e)}")
