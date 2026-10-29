const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// DISABLED: Attendance marking should NOT update streaks
// Streaks are managed separately through login tracking only
// Trigger: When attendance is marked (DISABLED - no streak updates)
// exports.onAttendanceMarked = functions.firestore
//   .document('attendance/{classId}/dates/{date}/students/{studentId}')
//   .onCreate(async (snap, context) => {
//     // Attendance marking is now separate from streak tracking
//     // Streaks are only updated when users log in, not when teachers mark attendance
//   });

// Trigger: When task is submitted
exports.onTaskSubmitted = functions.firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Check if any student submitted
    const beforeSubmissions = before.submissions || {};
    const afterSubmissions = after.submissions || {};
    
    for (const studentId in afterSubmissions) {
      if (afterSubmissions[studentId] === 'submitted' && 
          beforeSubmissions[studentId] !== 'submitted') {
        
        const task = after;
        const xpReward = task.xpReward || 50;
        
        // Add XP for submission
        await db.collection('users').doc(studentId).update({
          xp: admin.firestore.FieldValue.increment(25), // Base submission XP
        });
        
        // Check assignment badges
        await checkAssignmentBadges(studentId);
        
        // Send notification
        await sendNotification(studentId, {
          title: 'Task Submitted! ✅',
          body: `Your submission has been received!`,
        });
      }
    }
  });

// Trigger: When task is graded (award points automatically)
exports.onTaskGraded = functions.firestore
  .document('tasks/{taskId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    const beforeMarks = before.marks || {};
    const afterMarks = after.marks || {};
    const afterPointsAwarded = after.pointsAwarded || {};
    
    // Check if any student was graded
    for (const studentId in afterMarks) {
      const beforeMark = beforeMarks[studentId];
      const afterMark = afterMarks[studentId];
      const pointsAwarded = afterPointsAwarded[studentId] || 0;
      
      // If grade changed and points were awarded
      if (beforeMark !== afterMark && pointsAwarded > 0) {
        // Points are already updated in task_service.dart, but we can send notification
        await sendNotification(studentId, {
          title: '🎉 You earned points!',
          body: `You earned ${pointsAwarded} points for completing your homework!`,
        });
      }
    }
  });

// Helper: Check badges
async function checkBadges(studentId, streak) {
  const userRef = db.collection('users').doc(studentId);
  const userDoc = await userRef.get();
  
  if (!userDoc.exists) return;
  
  const userData = userDoc.data();
  const badges = userData.badges || [];
  
  // Consistency King/Queen (7-day streak)
  if (streak >= 7 && !badges.includes('consistency_king')) {
    await userRef.update({
      badges: admin.firestore.FieldValue.arrayUnion('consistency_king'),
      xp: admin.firestore.FieldValue.increment(150),
    });
    
    await sendNotification(studentId, {
      title: 'Badge Unlocked! 👑',
      body: 'You earned the Consistency King/Queen badge!',
    });
  }
}

// Helper: Check assignment badges
async function checkAssignmentBadges(studentId) {
  const userRef = db.collection('users').doc(studentId);
  const userDoc = await userRef.get();
  
  if (!userDoc.exists) return;
  
  const userData = userDoc.data();
  const badges = userData.badges || [];
  
  // Get all tasks assigned to this student
  const tasksSnapshot = await db.collection('tasks')
    .where('assignedTo', 'array-contains', studentId)
    .get();
  
  let completedOnTime = 0;
  
  tasksSnapshot.forEach(doc => {
    const task = doc.data();
    const submission = task.submissions?.[studentId];
    if (submission === 'submitted' || submission === 'completed') {
      const dueDate = task.dueDate.toDate();
      if (new Date() <= dueDate) {
        completedOnTime++;
      }
    }
  });
  
  // Assignment Ace (5 tasks on time)
  if (completedOnTime >= 5 && !badges.includes('assignment_ace')) {
    await userRef.update({
      badges: admin.firestore.FieldValue.arrayUnion('assignment_ace'),
      xp: admin.firestore.FieldValue.increment(100),
    });
    
    await sendNotification(studentId, {
      title: 'Badge Unlocked! ⭐',
      body: 'You earned the Assignment Ace badge!',
    });
  }
}

// Helper: Check attendance badges
async function checkAttendanceBadges(studentId) {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  
  const attendanceSnapshot = await db.collection('attendance')
    .where('studentId', '==', studentId)
    .where('date', '>', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
    .where('status', '==', 'present')
    .get();
  
  const presentDays = attendanceSnapshot.size;
  
  const userRef = db.collection('users').doc(studentId);
  const userDoc = await userRef.get();
  
  if (!userDoc.exists) return;
  
  const badges = userDoc.data().badges || [];
  
  // Attendance Hero (30 days)
  if (presentDays >= 30 && !badges.includes('attendance_hero')) {
    await userRef.update({
      badges: admin.firestore.FieldValue.arrayUnion('attendance_hero'),
      xp: admin.firestore.FieldValue.increment(200),
    });
    
    await sendNotification(studentId, {
      title: 'Badge Unlocked! 🎯',
      body: 'You earned the Attendance Hero badge!',
    });
  }
}

// Helper: Send notification
async function sendNotification(userId, notification) {
  try {
    // Get user's FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    
    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: notification,
        data: {
          type: 'badge' || 'streak' || 'task',
        },
      });
    }
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

// Scheduled function: Daily streak check
exports.dailyStreakCheck = functions.pubsub
  .schedule('every day 00:00')
  .timeZone('UTC')
  .onRun(async (context) => {
    // Check all students and reset streaks if they didn't attend
    const studentsSnapshot = await db.collection('users')
      .where('role', '==', 'student')
      .get();
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    for (const doc of studentsSnapshot.docs) {
      const studentId = doc.id;
      
      // Check if attendance was marked today
      // This is simplified - in production, check actual attendance records
      // For now, we'll just check if there's an attendance record
      
      // In a real implementation, you would check attendance records
      // and reset streak if absent
    }
  });

