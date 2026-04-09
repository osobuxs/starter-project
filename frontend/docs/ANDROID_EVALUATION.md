# Android evaluation

Android Firebase config is already committed in `android/app/google-services.json`.

For Android evaluation builds, both `debug` and `release` use the shared demo keystore at `android/app/demo-evaluator.keystore`, so evaluators do **not** need to create their own keystore or register a personal SHA fingerprint.

## What evaluators need to do

1. Open the Flutter project in `frontend/`.
2. Run the app from source or build an APK normally.
3. If you need the certificate fingerprints used by this repo, print them from the shared keystore:

```bash
keytool -list -v -keystore frontend/android/app/demo-evaluator.keystore -alias demo-evaluator -storepass android -keypass android
```

## Firebase Console

Evaluators do not need to register their own SHA fingerprints.

Project maintainers still need to do this **once** before evaluation:

1. Print the SHA-1 and SHA-256 from the shared keystore.
2. Open Firebase Console → Project settings → Your apps → Android app `com.osobuxs.newsapp.symmetry`.
3. Add both fingerprints to the Android app.
4. Re-download `android/app/google-services.json`.
5. Commit the updated file so evaluators inherit the working config.
