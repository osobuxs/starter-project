# Backend Rules Tests

This folder contains automated security tests for Firebase Firestore and Storage rules.

## Run

```bash
cd backend
npm install
npm run test:rules
```

## Files

- `firestore.rules.test.js` — ownership, visibility, favorites contract
- `storage.rules.test.js` — ownership and image-only uploads for storage paths

## Important

- Do **not** run `npm run test:rules:local` directly unless emulators are already running and environment variables are configured.
- Preferred entrypoint is `npm run test:rules` (it starts/stops emulators automatically).
