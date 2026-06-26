<div align="center">

<img src="assets/icon/icon.png" alt="Pick app icon" width="120" height="120" />

# 🎸 Pick

### A free, open-source guitar practice app for Android

**Drill chord changes, practise scales and lead, and lock into a built-in metronome — all in one clean, offline app.**

[![Download APK](https://img.shields.io/badge/⬇%20Download-Pick%20APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/shirrsho/Pick/releases/latest/download/Pick.apk)

[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](https://github.com/shirrsho/Pick/releases/latest)
[![Built with Flutter](https://img.shields.io/badge/built%20with-Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/shirrsho/Pick?sort=semver)](https://github.com/shirrsho/Pick/releases/latest)
[![Total downloads](https://img.shields.io/github/downloads/shirrsho/Pick/total)](https://github.com/shirrsho/Pick/releases)

🌐 **[Website](https://shirrsho.github.io/Pick/)**

</div>

---

## 📥 Download & install

1. **[⬇ Download the latest Pick APK](https://github.com/shirrsho/Pick/releases/latest/download/Pick.apk)** (or browse [all releases](https://github.com/shirrsho/Pick/releases)).
2. Open the downloaded `.apk` on your Android phone.
3. If prompted, allow **"Install from unknown sources"** for your browser or file manager.
4. Tap **Install** → **Open**. No ads, no sign-up, no internet required. 🎉

> Requires Android 5.0 (Lollipop) or newer.

---

## ✨ What is Pick?

**Pick** is a focused, distraction-free **guitar practice app**. Open it and choose what to work on — **Chords** or **Leads** — set a timing, hit play, and drill. A reminder widget keeps your streak alive, and everything works fully offline.

## 🎯 Features

### 🎵 Chords
- 🎲 **Randomized chord drills** — chords loop in random order so you build real recall.
- ⏱️ **Adjustable timing** — a 1–5s delay between changes, or sync to the metronome.
- 🎼 **Chords / Key / Loop modes** — drill any chords (select-all by default), the diatonic chords of a key, or a **custom loop** with a per-change delay.
- 🎸 **Fretboard diagrams** for every chord (barre chords drawn as a real bar); long-press to preview.

### 🎤 Leads (scales & soloing)
- 🪕 **Scale reference** — see any scale laid out on the full fretboard, roots highlighted.
- 🎯 **Timed note drill** — the app lights up notes to pluck in time (asc / desc / random) — great picking practice.
- 🔥 **Solo trainer** — improvise to random target notes over the metronome.
- 📚 **Built-in music-theory primer** — notes → steps → scales → keys → pentatonic & blues, in plain English.
- Scales: **Major, Natural minor, Minor/Major pentatonic, Blues** in any key.

### 🥁 Metronome & sessions
- **Tempo mode** with accented downbeat, audible click, beat dots, and an optional screen flash.
- **Timed sessions** (1 / 3 / 5 / 10 min) that end on a **congrats screen** with your session time and **all-time total**.
- ⏳ A 3·2·1 + one-bar count-in, and the screen stays awake while you play.

### 🏠 & more
- 🔴 **Home-screen widget** that turns red to remind you after 12 hours, and shows your lifetime practice time.
- 🌙 Clean dark UI, fully offline, lightweight, **100% free & open source**.

## 🛠️ Build from source

Pick is built with [Flutter](https://flutter.dev).

```bash
git clone https://github.com/shirrsho/Pick.git
cd Pick
flutter pub get
flutter run                 # run on a device / emulator
flutter build apk --release # build your own release APK
```

> Release signing reads from `android/key.properties` + a keystore that are **not** committed. Supply your own to sign a distributable build, or use `flutter build apk --debug`.

### Tech stack

- **Flutter / Dart** — cross-platform UI
- **CustomPainter** — hand-drawn chord & fretboard diagrams
- **audioplayers** — low-latency metronome clicks
- **home_widget** + **Kotlin** — the Android reminder widget

## 🤝 Contributing

Issues and PRs welcome — ideas: more scales/voicings, alternate tunings, note-pitch audio, iOS support, more widget sizes.

## 📄 License

Released under the [MIT License](LICENSE). Free to use, modify, and share.

---

<div align="center">

**Keywords:** guitar practice app · chord trainer · scale practice · guitar scales · lead guitar · soloing · pentatonic · fretboard trainer · guitar metronome · chord changes · learn guitar · free open source guitar app

Made with 🎸 and Flutter. If Pick helps your playing, consider giving it a ⭐ on GitHub!

</div>
