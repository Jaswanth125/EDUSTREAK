# 🔄 Activity Diagram Design Prompt for ChatGPT

Copy and paste this prompt to ChatGPT to get complete Activity Diagrams for the EduStreak educational application.

---

## PROJECT CONTEXT: EduStreak Educational Platform

I need you to create **comprehensive Activity Diagrams** for **EduStreak**, a gamified educational mobile application built with Flutter. Activity diagrams should show the flow of activities, decision points, and parallel processes for key workflows in the system.

---

## 🎯 KEY WORKFLOWS TO MODEL

### 1. **User Registration & Login Flow**
- Registration process
- Login authentication
- Profile setup

### 2. **Task Management Flow**
- Teacher creates and assigns task
- Student views and completes task
- Task submission and grading

### 3. **Streak Calculation Flow**
- Daily login check
- Streak maintenance/break logic
- XP and level updates

### 4. **Document Upload & Processing Flow**
- Student uploads document
- System processes document (chunking, embedding)
- Document storage in vector database

### 5. **AI Query Flow**
- Student asks question
- System retrieves relevant chunks
- LLM generates answer
- Response delivery

### 6. **Quiz Generation Flow**
- Student requests quiz
- System retrieves relevant content
- LLM generates questions
- Student takes quiz
- Score calculation

### 7. **Store Purchase Flow**
- Student browses store
- Selects item (avatar/badge)
- Checks balance
- Processes purchase
- Updates inventory

### 8. **Challenge Flow**
- Teacher creates challenge
- Student accepts challenge
- Progress tracking
- Challenge completion

### 9. **Attendance Marking Flow**
- Student marks attendance
- System validates
- Updates attendance record
- Awards XP

### 10. **Leaderboard Update Flow**
- System calculates rankings
- Updates leaderboard
- Notifies top performers

---

## 📊 DETAILED WORKFLOW SPECIFICATIONS

### **WORKFLOW 1: User Registration & Login**

#### Registration Flow
```
1. User opens app
2. Selects "Register"
3. Chooses role (Student/Teacher/Admin)
4. Enters email and password
5. System validates email format
6. System checks if email exists
   - If exists: Show error, return to step 4
   - If not: Continue
7. User enters additional info (name, etc.)
8. System creates Firebase account
9. System creates user document in Firestore
10. System initializes user stats (XP=0, Streak=0, Level=1)
11. System sends verification email
12. Registration complete
13. Redirect to login
```

#### Login Flow
```
1. User opens app
2. Enters email and password
3. System validates credentials with Firebase
   - If invalid: Show error, return to step 2
   - If valid: Continue
4. System fetches user data from Firestore
5. System checks user role
6. System loads appropriate dashboard
   - Student → Student Dashboard
   - Teacher → Teacher Dashboard
   - Admin → Admin Dashboard
7. System updates last login date
8. System checks streak eligibility
9. Login complete
```

---

### **WORKFLOW 2: Task Management**

#### Teacher Creates Task
```
1. Teacher navigates to Tasks screen
2. Teacher clicks "Create Task"
3. Teacher enters task details:
   - Title
   - Description
   - Due date
   - Points/XP reward
4. Teacher selects students/classes to assign
5. Teacher saves task
6. System validates task data
   - If invalid: Show error, return to step 3
   - If valid: Continue
7. System creates task document in Firestore
8. System sends notifications to assigned students
9. Task created successfully
```

#### Student Completes Task
```
1. Student views tasks list
2. Student selects a task
3. Student views task details
4. Student clicks "Complete Task"
5. System checks if task is already completed
   - If completed: Show message, end
   - If not: Continue
6. System checks if due date passed
   - If overdue: Mark as overdue, continue
   - If not: Continue
7. Student submits work (optional)
8. System marks task as completed
9. System awards XP to student
10. System updates student stats
11. System checks for level up
12. System updates leaderboard
13. System sends notification to teacher
14. Task completion recorded
```

---

### **WORKFLOW 3: Streak Calculation**

#### Daily Streak Check
```
1. User logs in
2. System gets current date
3. System retrieves user's last login date
4. System calculates days difference
5. Decision: Is last login date null?
   - Yes: Initialize streak to 1, continue
   - No: Continue
6. Decision: Is last login date today?
   - Yes: No change to streak, end
   - No: Continue
7. Decision: Is last login date yesterday?
   - Yes: Increment streak, continue
   - No: Reset streak to 1, continue
8. System updates streak count in Firestore
9. System updates last login date
10. System checks streak milestones
    - If milestone reached: Award badge, send notification
11. System awards bonus XP for streak
12. Streak updated
```

---

### **WORKFLOW 4: Document Upload & Processing**

#### Document Upload Flow
```
1. Student navigates to Study Assistant
2. Student clicks "Upload Document"
3. Student selects file (PDF/DOCX/TXT)
4. System validates file type
   - If invalid: Show error, return to step 3
   - If valid: Continue
5. System validates file size
   - If too large: Show error, return to step 3
   - If valid: Continue
6. System uploads file to Firebase Storage
7. System extracts text from file
   - PDF → PyPDF2 extraction
   - DOCX → python-docx extraction
   - TXT → Direct read
8. System checks if text extraction successful
   - If failed: Show error, end
   - If successful: Continue
9. System chunks text (RecursiveCharacterTextSplitter)
   - Chunk size: ~1000 characters
   - Overlap: ~200 characters
10. System generates embeddings for each chunk
    - Model: sentence-transformers
    - Parallel processing for multiple chunks
11. System stores chunks in ChromaDB
    - Store embeddings
    - Store metadata (filename, chunk_index, upload_date)
12. System creates document record in Firestore
13. System sends success notification
14. Document processing complete
```

---

### **WORKFLOW 5: AI Query Flow**

#### Question Answering Process
```
1. Student navigates to Study Assistant
2. Student types question
3. Student optionally selects specific documents
4. Student submits question
5. System generates embedding for question
   - Same model as documents
6. System performs vector similarity search in ChromaDB
   - Retrieve top-k chunks (k=3-5)
   - Filter by selected documents (if specified)
7. System ranks retrieved chunks by relevance
8. System builds context from chunks
   - Truncate if exceeds token limit (~12,000 chars)
9. System retrieves conversation history (if chat mode)
10. System constructs prompt:
    - System prompt: "You are a helpful tutor..."
    - Context: Retrieved chunks
    - Question: Student's question
    - History: Previous messages
11. System sends prompt to Groq LLM API
12. System waits for LLM response
    - If timeout: Show error, end
    - If success: Continue
13. System parses LLM response
14. System extracts answer and sources
15. System stores conversation in Firestore
16. System returns answer to student
17. Student views answer with source citations
```

---

### **WORKFLOW 6: Quiz Generation**

#### Quiz Creation & Taking Flow
```
1. Student navigates to Study Assistant
2. Student requests quiz
3. Student selects topic (optional)
4. Student selects documents (optional)
5. Student specifies number of questions
6. System retrieves relevant chunks
   - If topic specified: Filter by topic similarity
   - If documents specified: Filter by documents
   - Otherwise: Use all chunks
7. System builds context from chunks
8. System sends quiz generation request to LLM
   - Prompt: Generate multiple-choice questions
   - Include correct answers and explanations
9. System receives LLM response
10. System parses quiz questions
    - Extract questions, options, correct answers, explanations
11. System validates quiz format
    - If invalid: Show error, end
    - If valid: Continue
12. System displays quiz to student
13. Student answers questions
14. System collects student answers
15. System calculates score
    - Compare answers with correct answers
    - Calculate percentage
16. System displays results
    - Show score
    - Show correct/incorrect answers
    - Show explanations
17. System stores quiz results in Firestore
18. System awards XP based on score
19. Quiz complete
```

---

### **WORKFLOW 7: Store Purchase**

#### Avatar/Badge Purchase Flow
```
1. Student navigates to Store
2. Student browses items (Avatars/Badges)
3. Student selects an item
4. Student views item details (name, description, price)
5. Student clicks "Purchase"
6. System checks if item already owned
   - If owned: Show message, end
   - If not: Continue
7. System retrieves student's current XP/points
8. System compares with item price
   - If insufficient: Show error, suggest earning more XP, end
   - If sufficient: Continue
9. System deducts points from student balance
10. System adds item to student's inventory
11. System updates Firestore:
    - Update student points
    - Add item to owned items list
12. System sends purchase confirmation notification
13. Purchase complete
14. Student can now use item (set as avatar, display badge)
```

---

### **WORKFLOW 8: Challenge Flow**

#### Challenge Creation & Completion
```
1. Teacher creates challenge
2. Teacher sets challenge details:
   - Name, description
   - Duration, goals
   - Rewards (XP, badges)
3. Teacher assigns to students/classes
4. System creates challenge in Firestore
5. System sends notifications to students
6. Student receives notification
7. Student views challenge details
8. Student accepts challenge
9. System adds student to challenge participants
10. System tracks student progress
    - Monitor task completions
    - Track activity
11. Student completes challenge activities
12. System updates challenge progress
13. System checks if challenge goals met
    - If not: Continue tracking
    - If yes: Continue
14. System marks challenge as completed for student
15. System awards rewards (XP, badges)
16. System sends completion notification
17. Challenge complete
```

---

### **WORKFLOW 9: Attendance Marking**

#### Daily Attendance Flow
```
1. Student opens app
2. Student navigates to Attendance
3. Student clicks "Mark Attendance"
4. System gets current date and time
5. System checks if attendance already marked today
   - If yes: Show message, end
   - If no: Continue
6. System validates time window (if applicable)
   - If outside window: Show error, end
   - If valid: Continue
7. System creates attendance record in Firestore
   - Date, timestamp, student ID
8. System updates student's attendance stats
9. System awards XP for attendance
10. System checks streak (attendance contributes to streak)
11. System updates last login date
12. Attendance marked successfully
13. System shows confirmation
```

---

### **WORKFLOW 10: Leaderboard Update**

#### Ranking Calculation Flow
```
1. System triggers leaderboard update
   - Scheduled (daily/hourly)
   - Or triggered by activity (XP gain, task completion)
2. System retrieves all students
3. System calculates ranking metrics for each student:
   - Total XP
   - Current streak
   - Level
   - Tasks completed
4. System sorts students by ranking criteria
   - Primary: Total XP
   - Secondary: Streak
   - Tertiary: Level
5. System assigns ranks (1, 2, 3, ...)
6. System updates leaderboard in Firestore
7. System checks for rank changes
   - If significant change: Send notification
8. System identifies top performers
9. System sends achievement notifications
10. Leaderboard updated
```

---

## 🎯 ACTIVITY DIAGRAM REQUIREMENTS

### 1. **Standard UML Elements**
- **Start Node** (filled circle) - Beginning of process
- **Activity Nodes** (rounded rectangles) - Actions/activities
- **Decision Nodes** (diamonds) - Branching points with conditions
- **Merge Nodes** (diamonds) - Joining of flows
- **Fork Nodes** (horizontal bar) - Parallel activities start
- **Join Nodes** (horizontal bar) - Parallel activities end
- **End Node** (filled circle with border) - End of process
- **Swimlanes** (optional) - Separate lanes for different actors/systems

### 2. **Decision Points**
- Use clear labels: [Yes/No], [Valid/Invalid], [Success/Failure]
- Show all possible paths
- Include error handling paths

### 3. **Parallel Activities**
- Show fork/join for parallel processing
- Example: Generating embeddings for multiple chunks simultaneously
- Example: Updating multiple database records

### 4. **Swimlanes** (if applicable)
- **Student Lane** - Student actions
- **System Lane** - Automated system processes
- **Teacher Lane** - Teacher actions (for task creation)
- **AI/LLM Lane** - External AI service interactions

### 5. **Error Handling**
- Show error paths clearly
- Show retry mechanisms (if any)
- Show error notifications to users

### 6. **Loops/Iterations**
- Show loops for repetitive processes
- Example: Processing multiple chunks, iterating through students

---

## 📋 SPECIFIC DIAGRAMS TO CREATE

### Priority 1 (Core Workflows)
1. **User Registration & Login Activity Diagram**
2. **Task Completion Activity Diagram** (Student perspective)
3. **Streak Calculation Activity Diagram**
4. **Document Upload & Processing Activity Diagram**
5. **AI Query Activity Diagram**

### Priority 2 (Secondary Workflows)
6. **Quiz Generation Activity Diagram**
7. **Store Purchase Activity Diagram**
8. **Challenge Flow Activity Diagram**
9. **Attendance Marking Activity Diagram**
10. **Leaderboard Update Activity Diagram**

---

## 🎯 YOUR TASK: CREATE ACTIVITY DIAGRAMS

Please provide:

### 1. **Complete Activity Diagrams**
- Visual diagrams in UML format
- All workflows clearly shown
- Decision points with conditions
- Parallel activities (fork/join)
- Error handling paths
- Swimlanes (if applicable)

### 2. **Diagram Elements**
- Start and end nodes clearly marked
- Activity nodes with descriptive names
- Decision nodes with clear conditions
- Flow directions (arrows)
- Guards/conditions on transitions
- Notes/explanations where needed

### 3. **Workflow Descriptions**
- Brief description of each workflow
- Key decision points explained
- Parallel activities identified
- Error scenarios handled

### 4. **Swimlane Organization** (if used)
- Clear separation of actor responsibilities
- System processes in dedicated lane
- External service interactions shown

---

## 📊 DIAGRAM FORMAT

Please provide diagrams in one of these formats:
1. **Mermaid diagram code** (preferred for easy integration)
2. **PlantUML code** (alternative)
3. **Textual description** with clear structure
4. **Visual description** that can be drawn in tools like Draw.io, Lucidchart, or Visual Paradigm

---

## ✅ DELIVERABLES

For each workflow, provide:

1. **Activity Diagram** (visual representation)
2. **Workflow Description** (textual explanation)
3. **Decision Points** (list of all decision nodes and conditions)
4. **Parallel Activities** (identification of fork/join points)
5. **Error Scenarios** (error handling paths)
6. **Swimlanes** (if applicable, actor responsibilities)

---

## 🔍 SPECIFIC FOCUS AREAS

### 1. **Complex Decision Logic**
- Streak calculation (multiple conditions)
- Task completion validation
- Purchase validation (balance check, ownership check)

### 2. **Parallel Processing**
- Document chunking and embedding generation
- Multiple database updates
- Notification sending

### 3. **Error Handling**
- Network failures
- API timeouts
- Invalid input validation
- Database errors

### 4. **External Service Integration**
- Firebase Authentication
- Firestore database operations
- Groq LLM API calls
- ChromaDB vector search
- Firebase Storage uploads

---

**Please create comprehensive, well-structured Activity Diagrams that accurately represent all key workflows in the EduStreak educational platform, showing clear decision points, parallel activities, and error handling.**

---

*Focus on clarity, completeness, and proper UML notation. Ensure all decision points are clearly labeled and all possible paths are shown.*








