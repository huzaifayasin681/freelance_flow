# Firebase Setup Guide for FreelanceFlow

## 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Name your project: `freelanceflow-[your-name]`
4. Enable Google Analytics (optional)
5. Create project

## 2. Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get started"
3. Go to **Sign-in method** tab
4. Enable **Email/Password**
5. Enable **Google** sign-in
   - Enter your project's support email
   - Download the config files when prompted

## 3. Create Firestore Database

1. Go to **Firestore Database**
2. Click "Create database"
3. Choose "Start in test mode" (we'll secure it later)
4. Select a location close to your users
5. Create database

## 4. Set up Firebase Storage

1. Go to **Storage**
2. Click "Get started"
3. Choose "Start in test mode"
4. Use the same location as Firestore

## 5. Enable Cloud Messaging

1. Go to **Cloud Messaging**
2. No additional setup needed for now

## 6. Add Android App

1. In Project Overview, click "Add app" → Android
2. Enter package name: `com.freelanceflow.app`
3. Enter app nickname: `FreelanceFlow Android`
4. Download `google-services.json`
5. Place file in `android/app/`

## 7. Add iOS App (if needed)

1. In Project Overview, click "Add app" → iOS
2. Enter bundle ID: `com.freelanceflow.app`
3. Enter app nickname: `FreelanceFlow iOS`
4. Download `GoogleService-Info.plist`
5. Place file in `ios/Runner/`

## 8. Update Firebase Configuration

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Run: `flutter pub add firebase_core firebase_auth cloud_firestore`
4. Run: `flutterfire configure`
5. Follow the prompts to select your project

## 9. Firestore Security Rules

Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /clients/{clientId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    match /projects/{projectId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    match /tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    match /payments/{paymentId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 10. Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 11. Cloud Functions (Optional)

1. Initialize Functions: `firebase init functions`
2. Choose TypeScript
3. Install dependencies
4. Deploy: `firebase deploy --only functions`

## 12. Test Your Setup

1. Run `flutter run`
2. Try creating an account
3. Check Firebase Console to see if user was created
4. Test Google sign-in

## Troubleshooting

### Common Issues:

1. **SHA-1 fingerprint missing**: Add SHA-1 fingerprint in Firebase Console → Project Settings → Your apps
2. **Google sign-in not working**: Ensure OAuth consent screen is configured
3. **Firestore permission denied**: Check security rules and user authentication

### Getting SHA-1 Fingerprint:

For debug:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

For release:
```bash
keytool -list -v -keystore /path/to/my-release-key.keystore -alias alias_name
```

## Next Steps

1. Test all authentication flows
2. Verify Firestore read/write operations
3. Test file uploads to Storage
4. Set up Cloud Functions for payment reminders
5. Configure push notifications

## Support

If you encounter issues:
1. Check Firebase Console logs
2. Review Flutter debug console
3. Verify all configuration files are in place
4. Ensure all dependencies are installed