# deepsky_bluetooth_android

A new Flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Regenerating the Pigeon bindings

The IPC contract is defined in `pigeons/messages.dart`. The generated bindings
are **not tracked in git** — generate them locally (or in CI) before building or
analyzing, from this plugin's directory:

```sh
dart run pigeon --input pigeons/messages.dart
dart format lib/src/messages.g.dart
```

This generates:

- `lib/src/messages.g.dart` (ignored via the repo-wide `*.g.dart` rule)
- `android/src/main/kotlin/com/example/deepsky_bluetooth_android/Messages.g.kt`
  (ignored via this plugin's `.gitignore`)

Pigeon's bundled formatter differs from the SDK's `dart format`, so the second
command normalizes the Dart output to the project's formatting. The Kotlin
output is used as emitted by Pigeon. Both steps are deterministic, so generation
is reproducible; verify with `flutter analyze` from the workspace root.

