import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import 'database_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));
  final _db = DatabaseService();

  /// chapterId → download progress 0.0–1.0
  final Map<String, double> progress = {};
  final Map<String, bool> _cancelled = {};

  // ─── Download ────────────────────────────────────────────────

  Future<void> downloadChapter(
    Manga manga,
    Chapter chapter,
    List<String> pageUrls, {
    void Function(double progress)? onProgress,
  }) async {
    progress[chapter.id] = 0.0;
    _cancelled[chapter.id] = false;

    final dir = await _chapterDir(manga, chapter);
    final localPaths = <String>[];

    for (int i = 0; i < pageUrls.length; i++) {
      if (_cancelled[chapter.id] == true) break;

      final url = pageUrls[i];
      final ext = _ext(url);
      final filePath = '$dir/page_${i.toString().padLeft(4, '0')}.$ext';

      try {
        await _dio.download(
          url,
          filePath,
          options: Options(headers: {
            'Referer': manga.url,
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
          }),
        );
        localPaths.add(filePath);
      } catch (_) {
        // Keep the remote URL as fallback so reading still works
        localPaths.add(url);
      }

      final p = (i + 1) / pageUrls.length;
      progress[chapter.id] = p;
      onProgress?.call(p);
    }

    if (_cancelled[chapter.id] != true) {
      chapter.isDownloaded = true;
      chapter.localPages = localPaths;
      await _db.saveChapter(chapter);
    }

    progress.remove(chapter.id);
    _cancelled.remove(chapter.id);
  }

  /// Cancel an in-progress download.
  void cancel(String chapterId) => _cancelled[chapterId] = true;

  /// Delete downloaded files and mark chapter as not downloaded.
  Future<void> deleteDownload(Manga manga, Chapter chapter) async {
    final dir = Directory(await _chapterDir(manga, chapter));
    if (await dir.exists()) await dir.delete(recursive: true);
    chapter.isDownloaded = false;
    chapter.localPages = [];
    await _db.saveChapter(chapter);
  }

  bool isDownloading(String chapterId) => progress.containsKey(chapterId);

  // ─── Helpers ─────────────────────────────────────────────────

  Future<String> _chapterDir(Manga manga, Chapter chapter) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/smanga/${manga.id}/${chapter.id}');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  String _ext(String url) {
    try {
      final path = Uri.parse(url).path;
      final dotIdx = path.lastIndexOf('.');
      if (dotIdx != -1) return path.substring(dotIdx + 1).toLowerCase();
    } catch (_) {}
    return 'jpg';
  }
}
