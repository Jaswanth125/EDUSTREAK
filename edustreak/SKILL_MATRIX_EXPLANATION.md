# Skill Matrix Calculation - How It Works

## ✅ **100% LIVE PERFORMANCE BASED - NOT HARDCODED**

The Skill Matrix is calculated in **real-time** from actual student performance data stored in Firestore. Here's how each skill is calculated:

---

## 📊 **Skill Breakdown**

### 1. **Attendance (0-100%)**
- **Data Source**: `attendanceSummary` collection (monthly attendance records)
- **Calculation**: 
  - Fetches current month's attendance summary
  - Calculates: `(Present Days / Total Working Days) × 100`
- **Updates**: Real-time as teachers mark attendance

### 2. **Task Performance (0-100%)**
- **Data Source**: `taskSubmissions` collection
- **Calculation**:
  - **Completion Rate (40% weight)**: `(Completed Tasks / Total Tasks) × 100`
  - **Average Grade (60% weight)**: `(Total Marks / Max Marks) × 100`
  - **Final Score**: `(Completion Rate × 0.4) + (Average Grade × 0.6)`
- **Updates**: Real-time when tasks are submitted and graded

### 3. **Engagement (0-100%)**
- **Data Source**: User's XP and Level from `users` collection
- **Calculation**:
  - **XP Score (50 points)**: `(Current XP / 10000) × 50` (capped at 100%)
  - **Level Score (50 points)**: `(Current Level / 20) × 50` (capped at 100%)
  - **Final Score**: XP Score + Level Score
- **Updates**: Real-time as students earn XP and level up

### 4. **Participation (0-100%)**
- **Data Source**: User's streak and badges from `users` collection
- **Calculation**:
  - **Streak Score (50 points)**: `(Current Streak / 30) × 50` (capped at 100%)
  - **Badge Score (50 points)**: `(Badge Count / 10) × 50` (capped at 100%)
  - **Final Score**: Streak Score + Badge Score
- **Updates**: Real-time as students maintain streaks and earn badges

### 5. **Challenge Completion (0-100%)**
- **Data Source**: `challenges` collection
- **Calculation**:
  - Fetches all challenges assigned to the student
  - Counts completed challenges
  - **Final Score**: `(Completed Challenges / Total Assigned Challenges) × 100`
- **Updates**: Real-time when challenges are completed

### 6. **Overall Progress (0-100%)**
- **Data Source**: Combined metrics from user profile
- **Calculation**:
  - **XP Progress (30 points)**: `(XP / 10000) × 30`
  - **Level Progress (30 points)**: `(Level / 20) × 30`
  - **Streak Progress (20 points)**: `(Streak / 30) × 20`
  - **Badge Progress (20 points)**: `(Badges / 10) × 20`
  - **Final Score**: Sum of all progress components
- **Updates**: Real-time as any metric changes

---

## ⚡ **Performance Optimizations**

1. **Parallel Data Fetching**: All Firestore queries run simultaneously
2. **Count Queries**: Uses Firestore count queries instead of fetching full documents
3. **Attendance Summary**: Uses pre-aggregated monthly summaries instead of individual records
4. **Limited Queries**: Limits task/challenge queries to recent 50-100 items
5. **Client-Side Calculations**: Most calculations done in memory for speed

---

## 🔄 **Real-Time Updates**

- Skill Matrix updates automatically when:
  - ✅ Attendance is marked
  - ✅ Tasks are submitted/graded
  - ✅ XP is earned
  - ✅ Levels are gained
  - ✅ Streaks are maintained
  - ✅ Badges are earned
  - ✅ Challenges are completed

**No manual refresh needed** - data is always current!

---

## 📈 **Example Calculation**

If a student has:
- **Attendance**: 18 present days out of 20 = **90%**
- **Tasks**: 8 completed out of 10 (80% completion), Average grade 85% = **83%**
- **XP**: 5000 XP, Level 10 = **75%**
- **Streak**: 15 days, 5 badges = **50%**
- **Challenges**: 3 completed out of 5 = **60%**
- **Overall**: Combined metrics = **70%**

The radar chart will show these exact percentages - **all calculated from live data!**

