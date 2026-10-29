# Database Architecture - EduStreak

## Overview
EduStreak uses **TWO different databases** for different purposes:

---

## 1. Firebase Firestore (Main Database) 🔥

**Used for:** All main app data and real-time features

### Collections:
- **`users`** - User profiles (students, teachers, parents, admins)
  - Fields: name, email, role, xp, streak, badges, points, classId, etc.
  
- **`tasks`** - Assignments and homework
  - Fields: title, description, dueDate, assignedTo, maxMarks, xpReward, etc.
  
- **`store`** - Store items and badges
  - `store/{itemId}` - Individual store items
  - `store/badges` - Badge collection
  
- **`chats`** - Chat conversations
  - `chats/{chatId}` - Chat metadata
  - `chats/{chatId}/messages` - Messages in each chat
  
- **`attendance`** - Attendance records
  - Fields: classId, studentId, date, status, etc.
  
- **`challenges`** - Learning challenges
  - Fields: title, description, xpReward, participants, etc.
  
- **`classes`** - Class information
  - Fields: name, teacherId, studentIds, etc.

### Why Firebase?
- ✅ Real-time updates
- ✅ Cloud-based (accessible from anywhere)
- ✅ Built-in authentication
- ✅ Scalable
- ✅ Offline support

---

## 2. SQLite Database (Study Assistant) 📚

**Used for:** Study Assistant feature only

### Location:
```
study_assistant (2)/study_assistant (1)/study.db
```

### Tables:
- **`topics`** - Topics for each unit
  - Fields: id, unit, name
  
- **`subtopics`** - Subtopics under each topic
  - Fields: id, topic_id, name, time_estimate
  
- **`materials`** - Uploaded study materials
  - Fields: id, unit, file_name, file_path, upload_date

### Why SQLite?
- ✅ Fast local access
- ✅ Perfect for structured educational content
- ✅ Works with RAG (Retrieval-Augmented Generation)
- ✅ No internet required for content access
- ✅ Easy to manage and update

---

## 3. Firebase Authentication 🔐

**Used for:** User authentication

- Email/Password authentication
- User session management
- ID tokens for backend API authentication

---

## Data Flow

### Main App Features:
```
Flutter App → Firebase Firestore
- Users, Tasks, Store, Chats, etc.
```

### Study Assistant Feature:
```
Flutter App → FastAPI Backend → SQLite Database
- Topics, Subtopics, Study Materials
```

### Authentication:
```
Flutter App → Firebase Auth → Firebase Firestore (users collection)
```

---

## Summary

| Feature | Database | Location |
|---------|----------|----------|
| User Profiles | Firebase Firestore | Cloud |
| Tasks & Assignments | Firebase Firestore | Cloud |
| Store & Badges | Firebase Firestore | Cloud |
| Chats & Messages | Firebase Firestore | Cloud |
| Attendance | Firebase Firestore | Cloud |
| **Study Assistant Topics** | **SQLite** | **Local (`study.db`)** |
| **Study Assistant Materials** | **SQLite** | **Local (`study.db`)** |
| Authentication | Firebase Auth | Cloud |

---

## Why This Architecture?

1. **Firebase Firestore** handles all user-generated and real-time data
2. **SQLite** handles structured educational content that:
   - Doesn't change frequently
   - Needs fast local access
   - Works with RAG for AI content generation
   - Can be easily updated by admins

Both databases work together to provide a complete learning platform! 🚀

