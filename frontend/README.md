# Flutter Frontend
In this folder are all the [Flutter](https://docs.flutter.dev/) related files.
This folder is essentially the app and what the user sees. 
It has a dependency to the backend which ensures that there is data consistency.
You will be doing most of your work in this folder.

## Getting Started
Android evaluators can use the committed Firebase config and shared demo keystore without adding their own SHA fingerprints once the maintainer has registered the shared keystore fingerprints in Firebase and committed the refreshed `google-services.json`.

For full local prerequisites (Flutter, JDK, Android SDK/adb, Node/npm) and exact evaluation steps, see:

- [`../DocsV2/05-delivery/EVALUATOR_QUICKSTART.md`](../DocsV2/05-delivery/EVALUATOR_QUICKSTART.md)

See [Android evaluation](./docs/ANDROID_EVALUATION.md) for the zero-setup Android flow.

If you are wiring the project to a different Firebase backend, follow the [backend tutorial](../backend/README.md) and your normal Firebase setup flow for that separate project.

### Generate files for routing, di etc.:
`flutter pub run build_runner build --delete-conflicting-outputs`
### Generate the icons:
`flutter pub run flutter_launcher_icons`
### Install the Project Dependencies (in pubsec.yaml)
`flutter pub get`

## Build APK (one command)

Desde `frontend/`:

### Windows (recomendado)

PowerShell / CMD:

```bash
build_apk.bat
```

Git Bash:

```bash
./build_apk.bat
```

### Linux/macOS

```bash
dart run tool/build_apk.dart
```

Qué hace este comando:

1. Ejecuta `flutter pub get`
2. Ejecuta `flutter build apk --release`
3. Copia el APK generado a `frontend/apk/`

Artefactos de salida:

- `frontend/apk/symmetry-news-v<version>-release.apk`
- `frontend/apk/latest-release.apk`

La versión se lee automáticamente desde `pubspec.yaml` (`version:`).

> Si ejecutás `flutter build apk --release` manualmente, Flutter deja el APK en `build/app/outputs/flutter-apk/`. El script `build_apk.bat` / `tool/build_apk.dart` además lo copia a `frontend/apk/`.

### How can I best understand this project?
In order to best understand this project and its underlying intricacies, we recommend that you watch this tutorial: [Flutter Clean Architecture Tutorial](https://www.youtube.com/watch?v=7V_P6dovixg).
This tutorial **literally builds this project from the ground up** so we really recommend you watch it before developing.

Furthermore, we will now leave the index of this project with all the documentation that must be read before contributing to the frontend.

# Index
1. [Contribution Guidelines](./docs/CONTRIBUTION_GUIDELINES.md)
2. [Architecture Violations](./docs/ARCHITECTURE_VIOLATIONS.md)
3. [Code Quality Violations](./docs/CODING_GUIDELINES.md)
4. [Our App Architecture](./docs/APP_ARCHITECTURE.md)
