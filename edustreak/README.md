# EDUSTREAK Premium Gamified Educational Ecosystem

## Overview
EDUSTREAK is a premium gamified educational ecosystem designed to enhance learning experiences through interactive and engaging methods. The application leverages a Retrieval-Augmented Generation (RAG) architecture to provide personalized educational content and support.

## Features
- User authentication and role-based access
- Gamification elements to enhance user engagement
- Dynamic content retrieval using RAG architecture
- User-friendly interface with customizable components

## Project Structure
```
edustreak
├── lib
│   ├── main.dart
│   ├── models
│   │   └── user_model.dart
│   ├── screens
│   │   ├── home_screen.dart
│   │   └── login_screen.dart
│   ├── services
│   │   ├── api_service.dart
│   │   └── rag_service.dart
│   ├── utils
│   │   └── constants.dart
│   └── widgets
│       ├── custom_button.dart
│       └── custom_textfield.dart
├── pubspec.yaml
└── README.md
```

## Setup Instructions
1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```
   cd edustreak
   ```
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Run the application:
   ```
   flutter run
   ```

## Usage Guidelines
- Users can log in using their credentials on the login screen.
- After logging in, users will be directed to the home screen, where they can access various educational resources and gamified features.
- The application adapts content based on user roles and preferences.

## Contribution
Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License
This project is licensed under the MIT License.