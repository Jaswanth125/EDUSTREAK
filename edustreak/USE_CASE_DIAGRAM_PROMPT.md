# 📊 Use Case Diagram Design Prompt for ChatGPT

Copy and paste this prompt to ChatGPT to get a complete Use Case Diagram for the EduStreak educational application.

---

## PROJECT CONTEXT: EduStreak Educational Platform

I need you to create a **comprehensive Use Case Diagram** for **EduStreak**, a gamified educational mobile application built with Flutter. The system includes student engagement tracking, teacher management, admin analytics, and an AI-powered study assistant.

---

## 👥 ACTORS (USER ROLES)

### 1. **Student**
- Primary user of the application
- Engages with learning content, tracks progress, earns rewards
- Uses AI Study Assistant for help with studies

### 2. **Teacher**
- Manages students, assigns tasks/challenges
- Monitors student progress and engagement
- Can revoke student streaks under special circumstances

### 3. **Admin**
- System administrator
- Views analytics and system-wide statistics
- Manages overall platform health

### 4. **System** (External System)
- Automated processes (notifications, streak calculations, etc.)

---

## 🎯 MAIN FEATURES & USE CASES

### **STUDENT USE CASES**

#### Authentication & Profile
- **Register Account** - Create new student account
- **Login** - Authenticate and access account
- **View Profile** - See personal information and stats
- **Edit Profile** - Update personal details
- **Logout** - End session

#### Dashboard & Progress
- **View Dashboard** - See overview of progress, streaks, XP, level
- **View Statistics** - See detailed stats (streak count, total XP, level, badges earned)
- **View Leaderboard** - See rankings compared to other students
- **View Progress History** - See historical progress data

#### Tasks & Challenges
- **View Tasks** - See all assigned tasks from teachers
- **View Task Details** - See full task information (description, due date, points)
- **Complete Task** - Mark task as completed
- **Submit Task** - Submit task work/answers
- **View Challenges** - See available challenges
- **Accept Challenge** - Join a challenge
- **View Challenge Progress** - Track challenge completion

#### Gamification
- **Earn XP** - Gain experience points from activities
- **Maintain Streak** - Keep daily login streak active
- **View Badges** - See all earned badges
- **View Avatars** - See available avatar options
- **Purchase Avatar** - Buy avatar using earned points
- **Purchase Badge** - Buy badge using earned points
- **View Level** - See current level and progress to next level

#### Store
- **Browse Store** - View available avatars and badges
- **Purchase Items** - Buy avatars/badges with earned points
- **View Inventory** - See owned items

#### AI Study Assistant
- **Upload Document** - Upload PDF, DOCX, or TXT files
- **View Uploaded Documents** - See list of uploaded study materials
- **Ask Question** - Ask questions about uploaded documents
- **Get Answer** - Receive AI-generated answers based on documents
- **Request Summary** - Get summary of uploaded documents
- **Generate Quiz** - Create interactive quiz from documents
- **Chat with Assistant** - Have conversational interaction with AI tutor
- **View Chat History** - See previous conversations

#### Attendance
- **Mark Attendance** - Check in for daily attendance
- **View Attendance History** - See past attendance records

#### Notifications
- **Receive Notifications** - Get push notifications for tasks, achievements, etc.
- **View Notifications** - See notification history

---

### **TEACHER USE CASES**

#### Authentication & Profile
- **Register Account** - Create new teacher account
- **Login** - Authenticate and access account
- **View Profile** - See teacher profile information
- **Edit Profile** - Update teacher details
- **Logout** - End session

#### Student Management
- **View Students List** - See all students in their classes
- **View Student Profile** - See detailed student information
- **View Student Progress** - See student's stats, streaks, XP, level
- **View Student Tasks** - See tasks assigned to specific student
- **Revoke Student Streak** - Reset student's streak to 0 (under special circumstances)

#### Task Management
- **Create Task** - Create new task for students
- **Edit Task** - Modify existing task details
- **Delete Task** - Remove a task
- **Assign Task** - Assign task to specific students or classes
- **View All Tasks** - See all created tasks
- **View Task Submissions** - See student submissions for tasks
- **Grade Task** - Evaluate and grade student submissions

#### Challenge Management
- **Create Challenge** - Create new challenge for students
- **Edit Challenge** - Modify challenge details
- **Delete Challenge** - Remove a challenge
- **Assign Challenge** - Assign challenge to students
- **View Challenge Progress** - Monitor student progress in challenges

#### Analytics
- **View Class Analytics** - See overall class performance
- **View Student Engagement** - See engagement metrics for students
- **Export Reports** - Generate and download reports

---

### **ADMIN USE CASES**

#### Authentication
- **Login** - Authenticate as admin
- **Logout** - End admin session

#### Analytics & Monitoring
- **View System Analytics** - See overall platform statistics
- **View User Statistics** - See total users, active users, etc.
- **View Engagement Metrics** - See daily/weekly/monthly engagement data
- **View Progress Tracker** - See progress trends across all users
- **View Revenue Analytics** - See financial metrics (if applicable)
- **Export Analytics** - Download analytics reports

#### System Management
- **Manage Users** - View, edit, or delete user accounts
- **Manage Content** - Manage platform content and settings
- **View System Health** - Monitor system performance and errors
- **Manage Notifications** - Configure system-wide notifications

---

### **SYSTEM USE CASES** (Automated)

- **Calculate Streak** - Automatically calculate and update daily streaks
- **Award XP** - Automatically award XP for completed activities
- **Check Level Up** - Automatically check and update user levels
- **Send Notifications** - Automatically send push notifications
- **Process Document** - Automatically process uploaded documents (chunking, embedding)
- **Update Leaderboard** - Automatically update rankings
- **Backup Data** - Automatically backup user data

---

## 🔗 RELATIONSHIPS & DEPENDENCIES

### Include Relationships
- **Include** relationships (e.g., "Login" includes "Authenticate User")
- **Extend** relationships (e.g., "Complete Task" extends "View Task Details")
- **Generalization** (e.g., Student and Teacher both inherit from "User")

### Actor Relationships
- Student, Teacher, and Admin all interact with authentication
- Student and Teacher both use task management (different perspectives)
- System automates many processes triggered by user actions

---

## 📋 SPECIFIC REQUIREMENTS

### 1. **Diagram Structure**
- Use standard UML Use Case Diagram notation
- Include all actors (Student, Teacher, Admin, System)
- Group related use cases into packages/subsystems if needed
- Show clear system boundary

### 2. **Use Case Organization**
- Group use cases by functional areas:
  - Authentication & Profile Management
  - Dashboard & Progress Tracking
  - Tasks & Challenges
  - Gamification (XP, Streaks, Badges, Avatars)
  - Store
  - AI Study Assistant
  - Student Management (Teacher)
  - Analytics (Admin)
  - System Automation

### 3. **Relationships**
- Show all **Include** relationships (mandatory)
- Show all **Extend** relationships (optional)
- Show **Generalization** where applicable
- Indicate actor associations clearly

### 4. **Clarity**
- Use clear, descriptive use case names
- Avoid overlapping or redundant use cases
- Ensure all major features are represented
- Show dependencies between use cases

---

## 🎯 YOUR TASK: CREATE USE CASE DIAGRAM

Please provide:

### 1. **Complete Use Case Diagram**
- Visual diagram in UML format
- All actors clearly labeled
- All use cases organized logically
- All relationships shown (Include, Extend, Generalization)
- System boundary indicated

### 2. **Use Case Descriptions**
- Brief description for each use case
- Preconditions (if any)
- Postconditions (if any)
- Main flow (basic steps)

### 3. **Actor Descriptions**
- Role and responsibilities of each actor
- Key interactions with the system

### 4. **Relationship Explanations**
- Explanation of Include relationships
- Explanation of Extend relationships
- Explanation of Generalization relationships

### 5. **Subsystem/Package Organization** (if applicable)
- Grouped use cases by functional area
- Clear boundaries between subsystems

---

## 📊 DIAGRAM FORMAT

Please provide the diagram in one of these formats:
1. **Mermaid diagram code** (preferred for easy integration)
2. **PlantUML code** (alternative)
3. **Textual description** with clear structure
4. **Visual description** that can be drawn in tools like Draw.io, Lucidchart, or Visual Paradigm

---

## ✅ DELIVERABLES

1. **Use Case Diagram** (visual representation)
2. **Use Case Catalog** (list of all use cases with descriptions)
3. **Actor Catalog** (list of all actors with descriptions)
4. **Relationship Matrix** (showing all relationships)
5. **Subsystem Breakdown** (if applicable)

---

**Please create a comprehensive, well-organized Use Case Diagram that accurately represents all features and interactions in the EduStreak educational platform.**

---

*Focus on clarity, completeness, and proper UML notation. Ensure all major features are represented and relationships are clearly shown.*








