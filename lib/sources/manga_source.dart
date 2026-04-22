import '../models/manga.dart';
import '../models/chapter.dart';

/// Abstract interface that every manga source must implement.
/// Adding a new source = creating a class that extends [MangaSource]
/// (or [MadaraSource] for Madara WordPress sites).
abstract class MangaSource {
  /// Unique internal identifier (e.g. 'lekmanga')
  String get id;

  /// Display name shown in the UI (Arabic OK)
  String get name;

  /// Root URL without trailing slash
  String get baseUrl;

  /// Favicon URL for the source icon
  String get iconUrl;

  /// Language code: 'ar', 'en', …
  String get language;

  /// Returns a page of popular manga.
  Future<List<Manga>> getPopular({int page = 1});

  /// Returns a page of recently updated manga.
  Future<List<Manga>> getLatest({int page = 1});

  /// Search manga by text query.
  Future<List<Manga>> search(String query, {int page = 1});

  /// Fetches full manga details (description, genres, status, author).
  Future<Manga> getMangaDetail(Manga manga);

  /// Fetches the full chapter list for a manga.
  Future<List<Chapter>> getChapters(Manga manga);

  /// Fetches the ordered list of page image URLs for a chapter.
  Future<List<String>> getChapterPages(Chapter chapter);
}
