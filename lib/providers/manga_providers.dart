import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import '../sources/source_manager.dart';
import '../services/database_service.dart';

// ─── Singletons ──────────────────────────────────────────────

final sourceManagerProvider = Provider((_) => SourceManager());
final databaseProvider = Provider((_) => DatabaseService());

// ─── Browse state ────────────────────────────────────────────

/// Currently selected source index in the browse tab.
final selectedSourceIndexProvider = StateProvider<int>((_) => 0);

/// The active MangaSource derived from the selected index.
final selectedSourceProvider = Provider((ref) {
  final idx = ref.watch(selectedSourceIndexProvider);
  return ref.watch(sourceManagerProvider).all[idx];
});

/// Popular vs Latest toggle.
enum BrowseMode { popular, latest }

final browseModeProvider =
    StateProvider<BrowseMode>((_) => BrowseMode.popular);

/// Live search query (empty = show popular/latest).
final searchQueryProvider = StateProvider<String>((_) => '');

// ─── Data providers ───────────────────────────────────────────

/// Manga list for the Browse screen.
/// Re-fetches automatically when source / mode / query changes.
final mangaListProvider = FutureProvider.autoDispose<List<Manga>>((ref) {
  final source = ref.watch(selectedSourceProvider);
  final mode = ref.watch(browseModeProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.trim().isNotEmpty) return source.search(query.trim());
  return mode == BrowseMode.popular
      ? source.getPopular()
      : source.getLatest();
});

/// Full manga details (description, genres, author, status).
final mangaDetailProvider =
    FutureProvider.autoDispose.family<Manga, Manga>((ref, manga) {
  final src = ref.watch(sourceManagerProvider).getById(manga.sourceId);
  return src != null ? src.getMangaDetail(manga) : Future.value(manga);
});

/// Chapter list for a manga.
final chaptersProvider =
    FutureProvider.autoDispose.family<List<Chapter>, Manga>((ref, manga) {
  final src = ref.watch(sourceManagerProvider).getById(manga.sourceId);
  return src != null ? src.getChapters(manga) : Future.value([]);
});

/// Page URLs for a chapter (local paths if downloaded, remote if not).
final chapterPagesProvider =
    FutureProvider.autoDispose.family<List<String>, Chapter>((ref, chapter) {
  if (chapter.isDownloaded && chapter.localPages.isNotEmpty) {
    return Future.value(chapter.localPages);
  }
  // sourceId is the first segment of mangaId, e.g. 'lekmanga'
  final sourceId = chapter.mangaId.split('_').first;
  final src = ref.watch(sourceManagerProvider).getById(sourceId);
  return src != null ? src.getChapterPages(chapter) : Future.value([]);
});

/// Library — all bookmarked manga.
final libraryProvider = FutureProvider<List<Manga>>((ref) {
  return ref.watch(databaseProvider).getBookmarkedManga();
});

/// Whether a specific manga is bookmarked.
final isBookmarkedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, mangaId) {
  return ref.watch(databaseProvider).isBookmarked(mangaId);
});
