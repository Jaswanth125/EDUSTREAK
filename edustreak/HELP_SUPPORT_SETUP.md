# Help & Support Firestore Setup Guide

This guide will help you set up the Firestore collection for the Help & Support feature.

## 🚀 Quick Setup (Recommended)

**Easiest Method - Use Admin Dashboard:**

1. **Login as Admin**: `admin@edustreak.com` / `admin123`
2. **Go to Admin Dashboard**
3. **Click the Help Icon** (❓) in the top right AppBar
4. **Click "Initialize"** in the confirmation dialog
5. **Done!** ✅ The support data will be created automatically

The data will include:
- User Guide with comprehensive instructions
- 8 FAQs with common questions
- 4 Contact Support team members

---

## 📝 Manual Setup (Alternative Method)

If you prefer to set up manually in Firebase Console:

Create a collection named: `support_info`

### Document 1: `user_guide`

```json
{
  "title": "User Guide",
  "content": "Welcome to EduStreak! This app helps you track your child's academic performance, attendance, and rewards. You can view progress, message teachers, and stay updated on homework and grades. Navigate through tabs like 'Child Progress', 'Leaderboard', 'Messages', and 'Profile' for complete access."
}
```

### Document 2: `faqs`

```json
{
  "title": "FAQs",
  "faqs": [
    {
      "question": "How can I see my child's homework?",
      "answer": "Go to the Homework tab under Child Progress to view all assigned and graded homework."
    },
    {
      "question": "How do I chat with my child's teacher?",
      "answer": "Tap the Messages tab at the bottom navigation to start a conversation with your child's class teacher."
    },
    {
      "question": "How can I update my contact details?",
      "answer": "Go to the Profile tab → Edit Profile → Update your contact info and save changes."
    },
    {
      "question": "How do I earn badges?",
      "answer": "Badges are awarded automatically when your child completes tasks like homework or maintains good attendance."
    }
  ]
}
```

### Document 3: `contact_support`

```json
{
  "title": "Contact Support",
  "contacts": [
    {
      "name": "K. Jaswanth",
      "phone": "9985145125"
    },
    {
      "name": "K. Jaswanth Pavan Kumar",
      "phone": "9581214074"
    },
    {
      "name": "D. Tejesh",
      "phone": "7780159328"
    },
    {
      "name": "S. Sohith",
      "phone": "8309507529"
    }
  ]
}
```

## How to Add Data in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database**
4. Click **Start collection** (if collection doesn't exist)
5. Collection ID: `support_info`
6. Add the three documents above with their respective IDs:
   - `user_guide`
   - `faqs`
   - `contact_support`

## Features

✅ **Dynamic Content**: All content is fetched from Firestore, so you can update it anytime without app updates.

✅ **User Guide Tab**: Displays scrollable guide content

✅ **FAQs Tab**: Shows expandable FAQ items

✅ **Contact Support Tab**: Lists support team members with click-to-call functionality

## Testing

1. Log in as a parent
2. Go to **Profile** tab
3. Tap **Help & Support**
4. Navigate through the three tabs to see:
   - User Guide content
   - FAQs (expandable)
   - Contact Support (with call buttons)

## Notes

- Phone numbers will open the device's dialer when clicked
- All data is loaded dynamically from Firestore
- If data is not available, appropriate error messages will be shown
- The app includes refresh functionality for each tab

