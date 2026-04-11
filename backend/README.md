# Firebase Firestore Backend

This folder contains the Firebase backend configuration used by the project.

## Current canonical docs

The real current backend contract is documented in:

- `DocsV2/04-backend/FIREBASE_CONTRACT.md`
- `DocsV2/04-backend/RULES_AND_INDEXES.md`
- `backend/docs/DB_SCHEMA.md` (legacy bridge file)

## Deploying rules

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Login
```bash
firebase login
```

### 3. Verify project id
Check `.firebaserc` and ensure it points to the intended Firebase project.

### 4. Deploy
```bash
firebase deploy
```

Or deploy specific parts:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```

## Local emulator
```bash
firebase emulators:start
```

## Legacy note

The original starter instructions were broader and more generic. This file now points to the actual implemented contract rather than repeating outdated TODOs.
