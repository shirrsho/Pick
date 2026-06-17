<div align="center">

<img src="assets/icon/icon.png" alt="LoopChords app icon" width="120" height="120" />

# 🎸 LoopChords

### A free, open-source guitar chord practice app for Android

**Loop through random chords on a timer — train your chord changes, learn scales, and build muscle memory.**

[![Download APK](https://img.shields.io/badge/⬇%20Download-LoopChords%20APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/shirrsho/LoopChords/releases/latest/download/LoopChords.apk)

[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](https://github.com/shirrsho/LoopChords/releases/latest)
[![Built with Flutter](https://img.shields.io/badge/built%20with-Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/shirrsho/LoopChords?sort=semver)](https://github.com/shirrsho/LoopChords/releases/latest)
[![Total downloads](https://img.shields.io/github/downloads/shirrsho/LoopChords/total)](https://github.com/shirrsho/LoopChords/releases)

</div>

---

## 📥 Download & install

1. **[⬇ Download the latest LoopChords APK](https://github.com/shirrsho/LoopChords/releases/latest/download/LoopChords.apk)** (or browse [all releases](https://github.com/shirrsho/LoopChords/releases)).
2. Open the downloaded `.apk` on your Android phone.
3. If prompted, allow **"Install from unknown sources"** for your browser or file manager.
4. Tap **Install** → **Open**. That's it — no ads, no sign-up, no internet required. 🎉

> Requires Android 5.0 (Lollipop) or newer.

---

## ✨ What is LoopChords?

**LoopChords** is a minimalist **guitar chord trainer** that flashes chords at you on a fixed interval so you can practise switching between them smoothly. Pick your chords, pick a delay, hit play — and a random chord appears big on screen with its **fretboard diagram**, while the next chord previews in the corner so you're always ready for the change.

It's perfect for beginners drilling open chords, and for intermediate players working through **diatonic scale chords** or custom progressions.

## 🎯 Features

- 🎲 **Randomized chord drills** — chords loop in random order so you never just memorize a sequence.
- ⏱️ **Adjustable timing** — choose a 1–5 second delay between chord changes to match your level.
- 🎼 **Three practice modes:**
  - **All** — the full library of majors, minors, and 7th chords.
  - **Scale** — the diatonic chords of a key (e.g. *C Major*, *A Minor*); deselect any you want to skip.
  - **Custom** — hand-pick exactly the chords you want to drill.
- 🎸 **Built-in fretboard diagrams** — every chord shows finger positions, open/muted strings, and **barre chords rendered as a real bar**.
- 👆 **Long-press any chord** while selecting to pop up its full diagram.
- ⏯️ **Practice player** — current chord huge in the center, next chord previewed bottom-right, with pause / skip / stop and a live **elapsed-time** counter.
- 🔴 **Home-screen widget** — a 2×2 widget that turns **red to remind you to practise** when it's been more than 6 hours since your last session.
- 🌙 **Clean dark UI**, fully offline, lightweight, and **100% free & open source**.

## 🎵 Practice modes in detail

| Mode | Use it when… |
|------|--------------|
| **All chords** | You want a full workout across every chord shape. |
| **Scale / key** | You're learning the chords that belong together in a song's key. |
| **Custom** | You're practising a specific song or progression. |

Included scales: **C, G, D, A, E, F, B♭ Major** and **A, E, D, B Minor** — each with its full set of diatonic chords.

## 🏠 The reminder widget

Add the **LoopChords** widget to your home screen (long-press your home screen → *Widgets* → *LoopChords*). It stays calm after you practise, then turns a bold **red "Time to practice!"** once 6+ hours pass — a gentle nudge to keep your streak going. Tap it to jump straight into the app.

## 🛠️ Build from source

LoopChords is built with [Flutter](https://flutter.dev).

```bash
# Clone
git clone https://github.com/shirrsho/LoopChords.git
cd LoopChords

# Get dependencies
flutter pub get

# Run on a connected device / emulator
flutter run

# Build your own release APK
flutter build apk --release
```

> The release signing config reads from `android/key.properties` and a keystore that are **not** committed to this repo. Without them, supply your own `android/key.properties` to sign a distributable build, or build a debug APK with `flutter build apk --debug`.

### Tech stack

- **Flutter / Dart** — cross-platform UI
- **CustomPainter** — hand-drawn chord / fretboard diagrams
- **home_widget** — bridges the practice timestamp to the native Android widget
- **Kotlin** — `AppWidgetProvider` for the home-screen reminder widget

## 🤝 Contributing

Issues and pull requests are welcome! Ideas: more chords / voicings, additional scales, a metronome or audio playback, iOS support, more widget sizes.

## 📄 License

Released under the [MIT License](LICENSE). Free to use, modify, and share.

---

<div align="center">

**Keywords:** guitar chords app · chord practice · chord trainer · learn guitar · guitar fretboard · chord changes · guitar scales · chord progression trainer · practice guitar Android · free guitar app · open source guitar app

Made with 🎸 and Flutter. If LoopChords helps your playing, consider giving it a ⭐ on GitHub!

</div>
