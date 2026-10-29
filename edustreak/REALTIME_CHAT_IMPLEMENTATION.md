# Real-Time Chat System Implementation

## Overview

EduStreak now includes a complete real-time messaging system built entirely on Firebase Firestore. No external messaging APIs or sockets required - pure Firestore real-time streaming.

## Architecture

### Core Components

1. **Chat Models** (`lib/models/`)
   - `chat_model.dart`: Chat metadata (participants, lastMessage, typing status, unread counts)
   - `message_model.dart`: Individual messages with status tracking (sent/delivered/read)

2. **Chat Service** (`lib/services/realtime_chat_service.dart`)
   - Real-time message streaming using Firestore `.snapshots()`
   - Chat creation with role-based access control
   - Typing indicators
   - Message status tracking
   - File uploads (images, documents)

3. **UI Screens** (`lib/screens/chat/`)
   - `realtime_chat_list_screen.dart`: List of all chats with real-time updates
   - `realtime_chat_screen.dart`: Individual chat conversation with live message streaming

4. **FCM Service** (`lib/services/fcm_service.dart`)
   - Firebase Cloud Messaging integration
   - Push notification handling
   - Token management

## Features

### ✅ Real-Time Messaging
- Messages appear instantly using Firestore streams
- No polling or refresh needed
- Automatic updates when new messages arrive

### ✅ Two Chat Contexts
- **Teacher ↔ Parent**: Academic updates, feedback, attendance discussion
- **Teacher ↔ Student**: Doubt clarification and study help

### ✅ Chat ID Convention
- Teacher-Parent: `chat_teacher<teacherId>_parent<parentId>`
- Teacher-Student: `chat_teacher<teacherId>_student<studentId>`

### ✅ Message Status
- **Sent**: Message has been sent
- **Delivered**: Message has been delivered to recipient
- **Read**: Message has been read by recipient

### ✅ Typing Indicators
- Real-time typing status
- Shows when other user is typing
- Automatically clears after 2 seconds of inactivity

### ✅ Unread Message Counts
- Tracks unread messages per chat
- Displays badge on chat list
- Resets when chat is opened

### ✅ File Attachments
- Support for images and documents
- Automatic file upload to Firebase Storage
- Platform-specific handling (web vs mobile)

### ✅ Offline Support
- Firestore handles offline persistence automatically
- Messages queue when offline
- Automatic sync when connection restored

## Firestore Structure

```
chats/
  {chatId}/
    participants: [userId1, userId2]
    chatType: "teacher_parent" | "teacher_student"
    teacherId: string
    parentId: string | null
    studentId: string | null
    lastMessage: string
    lastTimestamp: timestamp
    createdAt: timestamp
    typing: {userId: bool}
    lastSeen: {userId: timestamp}
    unreadCount: {userId: int}
    messages/
      {messageId}/
        chatId: string
        senderId: string
        senderName: string
        text: string
        timestamp: timestamp
        status: "sent" | "delivered" | "read"
        readBy: {userId: timestamp}
        fileUrl: string | null
        fileName: string | null
        fileType: string | null
```

## Security Rules

Firestore security rules ensure:
- Only chat participants can read/write messages
- Users can only create chats with valid participants
- Message status updates are restricted to participants
- Typing indicators and unread counts are properly secured

See `firebase_rules.txt` for complete security rules.

## Usage

### Starting a Chat

```dart
final chatService = RealtimeChatService();

// Get or create a chat
final chat = await chatService.getOrCreateChat(
  currentUserId: currentUser.id,
  currentUserRole: currentUser.role,
  otherUserId: otherUser.id,
  otherUserRole: otherUser.role,
);
```

### Sending a Message

```dart
await chatService.sendMessage(
  chatId: chat.id,
  senderId: currentUser.id,
  senderName: currentUser.name,
  text: 'Hello!',
);
```

### Streaming Messages (Real-Time)

```dart
StreamBuilder<List<MessageModel>>(
  stream: chatService.getMessagesStream(chatId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    final messages = snapshot.data!;
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  },
)
```

### Typing Indicator

```dart
// Start typing
await chatService.setTyping(
  chatId: chatId,
  userId: currentUser.id,
  isTyping: true,
);

// Stop typing (automatically after 2 seconds)
await chatService.setTyping(
  chatId: chatId,
  userId: currentUser.id,
  isTyping: false,
);
```

## Navigation

Chat screens are integrated into all role dashboards:

- **Teacher Dashboard**: Chat tab (5th tab)
- **Student Dashboard**: Messages tab (5th tab)
- **Parent Dashboard**: Messages tab (2nd tab)

## FCM Notifications

Push notifications are sent via Firebase Cloud Functions when new messages arrive. See `FCM_SETUP_GUIDE.md` for setup instructions.

### Setup Steps

1. Enable FCM in Firebase Console
2. Deploy Cloud Function for notifications
3. Initialize FCM service in app
4. Store FCM tokens in Firestore

## Role-Based Access Control

### Teachers
- Can start chats with assigned students
- Can start chats with parents of students in their classes

### Students
- Can start chats with assigned teachers
- Cannot start chats with parents directly

### Parents
- Can start chats with teachers of their child
- Cannot start chats with students directly

## Performance Optimizations

1. **Message Pagination**: Load last 50 messages, paginate older ones
2. **Chat List Limit**: Show last 50 chats
3. **Batched Writes**: Use batch writes for multiple updates
4. **Offline Persistence**: Firestore handles offline automatically

## Testing

### Test Real-Time Updates
1. Open chat on two devices (or two browser tabs)
2. Send message from Device A
3. Message should appear instantly on Device B

### Test Typing Indicator
1. Open chat on two devices
2. Start typing on Device A
3. "typing..." should appear on Device B
4. Stop typing - indicator should disappear after 2 seconds

### Test Offline Support
1. Turn off internet on device
2. Send a message
3. Message should be queued locally
4. Turn on internet
5. Message should sync automatically

### Test Unread Counts
1. Send message from Device A to Device B
2. Unread count should increment on Device B
3. Open chat on Device B
4. Unread count should reset to 0

## Troubleshooting

### Messages not appearing in real-time
- Check Firestore security rules
- Verify user is authenticated
- Check network connection
- Verify user is a chat participant

### Typing indicator not working
- Check Firestore security rules allow typing updates
- Verify chatId is correct
- Check network connection

### FCM notifications not received
- Verify FCM token is stored in Firestore
- Check Cloud Functions are deployed
- Verify device notification permissions
- Check FCM service initialization

### File uploads failing
- Check Firebase Storage rules
- Verify file size limits
- Check network connection
- Verify platform-specific file handling

## Future Enhancements

- [ ] Message reactions (emoji)
- [ ] Message replies/threading
- [ ] Voice messages
- [ ] Video messages
- [ ] Group chats
- [ ] Message search
- [ ] Message forwarding
- [ ] Read receipts per message
- [ ] Message editing/deletion
- [ ] Chat archiving

## Support

For issues or questions, refer to:
- `FCM_SETUP_GUIDE.md`: FCM notification setup
- `firebase_rules.txt`: Security rules
- Firebase Console: Firestore data viewer

