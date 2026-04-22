import 'manga_source.dart';
import 'lekmanga_source.dart';
import 'mangalek_source.dart';
import 'mangaarab_source.dart';

/// Central registry for all manga sources.
/// Add new sources here — the rest of the app picks them up automatically.
class SourceManager {
  static final SourceManager _instance = SourceManager._internal();
  factory SourceManager() => _instance;

  SourceManager._internal() {
    _sources = [
      LekMangaSource(),
      MangaLekSource(),
      MangaArabSource(),
    ];
  }

  late final List<MangaSource> _sources;

  /// All registered sources.
  List<MangaSource> get all => _sources;

  /// Look up a source by its [id]. Returns null if not found.
  MangaSource? getById(String id) {
    try {
      return _sources.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
