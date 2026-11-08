# Headphone routing prototype

This personal fork keeps an experimental output mode for listening through headphones while Android Auto remains connected. Open Settings, then Headphone output, to select the headphones. Normal audio output returns control to Android.

The prototype started at `04b6120a21f544ed23eea78c134f94566c32ffb2`. The maintenance branch carries it onto upstream `00085b45`, with the original feature branch retained locally. Upstream's normal output selectors defer to the headphone selection while this mode is enabled.

The selected device is remembered across restarts. A disconnected selection pauses playback and refuses a new Play request until that device is available again. Reconnecting does not automatically resume playback.

## Automated checks

Use the Flutter version in `.flutter-version`:

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-pub lib/widgets/headphone_output_tile.dart tests/headphone_output_test.dart
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings lib/screens/settings_screen.dart
flutter test --no-pub tests/headphone_output_test.dart
```

The tests cover selecting headphones, restoring normal output, a disconnected selection, a rejected output change, and recovery after a failed device-list refresh. GitHub Actions runs the same checks without signing or publishing an app.

## Device checks before using a new build

- Play normally, then select connected headphones while Android Auto is active.
- Confirm that audio comes through the headphones and that car-screen controls still work.
- Disconnect the selected headphones. Confirm playback pauses and pressing Play does not send audio to the car or speaker.
- Reconnect, then press Play and confirm the selected route.
- Choose Normal audio output and check Android's output picker.
- Repeat after an app restart and after switching books.

These checks need a phone and car connection. Passing widget tests or compiling the Android source does not establish device routing behavior.
