# Smanga 📖

Arabic Manga & Manhwa reader for Android, built with Flutter.

---

## Features

| Feature | Details |
|---|---|
| 3 Arabic sources | LekManga, مانجا ليك, مانجا العرب |
| Browse | Popular & Latest tabs per source |
| Search | Per-source text search |
| Manga detail | Cover, description, genres, status, author |
| Chapter reader | Swipe pages, pinch-to-zoom via PhotoView |
| Offline download | Downloads all pages to internal storage |
| Reading progress | Auto-saved per chapter |
| Bookmarks | SQLite library — survive app restarts |
| Dark theme | #0D0D0D background, red accent |
| Arabic UI | All labels and messages in Arabic |

---

## Project Structure

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart
├── models/
│   ├── manga.dart
│   └── chapter.dart
├── sources/
│   ├── manga_source.dart       ← abstract interface
│   ├── madara_source.dart      ← Madara WordPress scraper (shared base)
│   ├── lekmanga_source.dart
│   ├── mangalek_source.dart
│   ├── mangaarab_source.dart
│   └── source_manager.dart     ← registry
├── services/
│   ├── database_service.dart   ← SQLite (bookmarks, downloads, progress)
│   └── download_service.dart   ← offline page downloader
├── providers/
│   └── manga_providers.dart    ← Riverpod state
├── screens/
│   ├── main_screen.dart
│   ├── browse_screen.dart
│   ├── library_screen.dart
│   ├── downloads_screen.dart
│   ├── manga_detail_screen.dart
│   └── reader_screen.dart
└── widgets/
    └── manga_card.dart
```

---

## Getting Started

### Requirements
- Flutter 3.19+
- Android SDK 21+ (Android 5.0 minimum)

### Install & run

```bash
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Adding a New Source

All three current sources use the WordPress Madara theme.
Adding a new Madara site takes **5 lines**:

```dart
// lib/sources/my_new_source.dart
import 'madara_source.dart';

class MyNewSource extends MadaraSource {
  @override String get id       => 'mynew';
  @override String get name     => 'My New Source';
  @override String get baseUrl  => 'https://mynewsite.com';
  @override String get iconUrl  => 'https://mynewsite.com/favicon.ico';
  @override String get language => 'ar';
}
```

Then register it in `source_manager.dart`:

```dart
_sources = [
  LekMangaSource(),
  MangaLekSource(),
  MangaArabSource(),
  MyNewSource(),   // ← add here
];
```

For non-Madara sites, extend `MangaSource` directly and implement all methods.

---

## Notes

- All scraping is done client-side — no backend server required.
- Madara AJAX endpoints are tried first for speed; HTML parsing is the fallback.
- Pages are cached in memory by `cached_network_image` while reading online.
- Downloaded chapters are stored under `getApplicationDocumentsDirectory()/smanga/`.
