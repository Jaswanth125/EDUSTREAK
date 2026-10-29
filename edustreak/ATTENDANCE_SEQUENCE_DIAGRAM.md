# Attendance Marking - Sequence Diagram

This document contains the sequence diagram for the attendance marking flow in the EduStreak application.

## Sequence Diagram

```mermaid
sequenceDiagram
    participant Teacher as Teacher (UI)
    participant AttendanceScreen as AttendanceScreen
    participant AttendanceService as AttendanceService
    participant Firestore as Firestore Database
    participant SummaryService as AttendanceSummaryService
    participant GamificationService as GamificationService
    participant Student as Student (UI)

    Note over Teacher,Student: Initial Setup
    Teacher->>AttendanceScreen: Open Attendance Screen
    AttendanceScreen->>Firestore: Load teacher's classes
    Firestore-->>AttendanceScreen: Return class list
    AttendanceScreen->>Teacher: Display class selector

    Note over Teacher,Student: Date & Class Selection
    Teacher->>AttendanceScreen: Select class & date
    AttendanceScreen->>AttendanceService: isAttendanceMarked(classId, dateKey)
    AttendanceService->>Firestore: Query attendanceRecords for any student in class
    Firestore-->>AttendanceService: Return attendance status
    AttendanceService-->>AttendanceScreen: Return isMarked (true/false)
    
    alt Attendance Already Marked
        AttendanceScreen->>Firestore: Load existing attendance records
        Firestore-->>AttendanceScreen: Return attendance data
        AttendanceScreen->>Teacher: Display locked attendance (read-only)
    else Attendance Not Marked
        AttendanceScreen->>Firestore: Load students in class
        Firestore-->>AttendanceScreen: Return student list
        AttendanceScreen->>Teacher: Display attendance marking UI
    end

    Note over Teacher,Student: Marking Attendance
    Teacher->>AttendanceScreen: Toggle attendance for students
    Teacher->>AttendanceScreen: Click "Submit Attendance"
    AttendanceScreen->>AttendanceService: markClassAttendance(classId, dateKey, studentAttendance, teacherId)
    
    Note over AttendanceService: Validation & Batch Write
    AttendanceService->>AttendanceService: isAttendanceMarked() - Double check
    alt Already Marked
        AttendanceService-->>AttendanceScreen: Throw Exception (Cannot mark twice)
        AttendanceScreen->>Teacher: Show error message
    else Not Marked - Proceed
        AttendanceService->>Firestore: Create batch write transaction
        loop For each student
            AttendanceService->>Firestore: Set attendanceRecord<br/>(users/{studentId}/attendanceRecords/{dateKey})
            Note right of Firestore: Fields: date, present, markedBy, timestamp
        end
        AttendanceService->>Firestore: Commit batch
        Firestore-->>AttendanceService: Batch committed successfully
        
        Note over SummaryService: Update Monthly Summary
        AttendanceService->>SummaryService: updateMonthlySummary(classId, date, studentAttendance)
        SummaryService->>Firestore: Get/Create attendanceSummary/{classId_YYYY-MM}
        alt Summary exists
            SummaryService->>SummaryService: Check if date already counted
            alt Date not counted
                SummaryService->>Firestore: Update presentDays/absentDays counts
                SummaryService->>Firestore: Increment totalWorkingDays
                SummaryService->>Firestore: Add date to markedDates array
            end
        else New summary
            SummaryService->>Firestore: Create new summary document
            SummaryService->>Firestore: Initialize presentDays/absentDays maps
            SummaryService->>Firestore: Set totalWorkingDays = 1
        end
        SummaryService-->>AttendanceService: Summary updated
        
        Note over GamificationService: Update Streaks & Check Badges
        loop For each student
            AttendanceService->>GamificationService: checkAttendanceBadges(studentId, date)
            GamificationService->>SummaryService: getStudentMonthlySummary(studentId, classId, month)
            SummaryService->>Firestore: Query attendanceSummary
            Firestore-->>SummaryService: Return monthly summary
            SummaryService-->>GamificationService: Return attendance percentage
            
            alt Present (increment streak)
                GamificationService->>GamificationService: updateStreak(studentId, increment=true)
                GamificationService->>Firestore: Update user.streak (increment by 1)
                GamificationService->>GamificationService: checkStreakBadges(studentId, newStreak)
            else Absent (reset streak)
                GamificationService->>GamificationService: updateStreak(studentId, increment=false)
                GamificationService->>Firestore: Update user.streak = 0
            end
            
            alt Badge criteria met
                GamificationService->>Firestore: Add badge to user.badges array
                GamificationService->>GamificationService: addXP(userId, badgeXP)
                GamificationService->>Firestore: Update user.xp and user.level
                GamificationService->>GamificationService: checkLevelBadges(userId, newLevel)
            end
        end
        GamificationService-->>AttendanceService: Badge checks complete
        
        AttendanceService-->>AttendanceScreen: Attendance marked successfully
        
        Note over AttendanceScreen,Student: Real-time Updates
        AttendanceScreen->>Teacher: Show success message
        Firestore->>Student: Real-time stream update (attendanceRecords)
        Firestore->>Student: Real-time stream update (user.streak, user.xp, user.badges)
        Student->>Student: Update calendar view
        Student->>Student: Update streak display
        Student->>Student: Show badge notification (if awarded)
    end
```

## Key Components

### 1. **Teacher Actions**
- Selects class and date
- Toggles attendance for each student (Present/Absent)
- Submits attendance

### 2. **Validation & Locking**
- System checks if attendance is already marked for the date/class
- Prevents duplicate marking (lock mechanism)
- Once submitted, attendance cannot be modified

### 3. **Data Storage**
- **Individual Records**: `users/{studentId}/attendanceRecords/{YYYY-MM-DD}`
- **Monthly Summary**: `attendanceSummary/{classId_YYYY-MM}`
- Uses Firestore batch writes for atomic operations

### 4. **Gamification Updates**
- **Streak Updates**:
  - Present → Increment streak by 1
  - Absent → Reset streak to 0
- **Badge Checks**:
  - Attendance badges (based on monthly percentage)
  - Streak badges (based on streak count)
  - Level badges (if level up occurs)
- **XP Awards**: Automatic XP for badges and level ups

### 5. **Real-time Updates**
- Students receive real-time updates via Firestore streams
- Calendar view updates automatically
- Streak and badge displays update in real-time

## Error Handling

- **Already Marked**: Throws exception if attendance is already marked
- **Network Errors**: Retry logic and error messages
- **Partial Failures**: Badge checks continue even if one student fails

## Performance Considerations

- **Batch Writes**: All attendance records written atomically
- **Parallel Processing**: Badge checks run in parallel for all students
- **Caching**: Monthly summaries cached to reduce queries
- **Streaming**: Real-time updates use Firestore streams for efficiency








