import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import 'manga_source.dart';

/// Reusable scraper for the WordPress **Madara** manga theme.
/// LekManga, MangaLeek, and MangaArabs all run on this theme,
/// so each source only needs to override the identity getters.
///
/// If a site deviates from standard Madara selectors,
/// override the relevant method in its subclass.
abstract class MadaraSource extends MangaSource {
  late final Dio _dio;

  MadaraSource() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'ar,en;q=0.8',
        'Referer': baseUrl,
      },
    ));
  }

  // ─── Popular ─────────────────────────────────────────────────

  @override
  Future<List<Manga>> getPopular({int page = 1}) async {
    // Try Madara AJAX endpoint first (faster, no full page load)
    try {
      final res = await _dio.post(
        '$baseUrl/wp-admin/admin-ajax.php',
        data: {
          'action': 'madara_load_more',
          'page': page - 1,
          'template': 'madara-core/content/content-archive-manga',
          'vars[paged]': page - 1,
          'vars[orderby]': 'meta_value_num',
          'vars[order]': 'DESC',
          'vars[meta_key]': '_wp_manga_chapter_type',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final items = _parseMangaList(res.data.toString());
      if (items.isNotEmpty) return items;
    } catch (_) {}

    // Fallback: parse popularity page HTML
    final res = await _dio.get('$baseUrl/manga/?m_orderby=views&page=$page');
    return _parseMangaList(res.data.toString());
  }

  // ─── Latest ──────────────────────────────────────────────────

  @override
  Future<List<Manga>> getLatest({int page = 1}) async {
    final res =
        await _dio.get('$baseUrl/manga/?m_orderby=latest&page=$page');
    return _parseMangaList(res.data.toString());
  }

  // ─── Search ──────────────────────────────────────────────────

  @override
  Future<List<Manga>> search(String query, {int page = 1}) async {
    final encoded = Uri.encodeComponent(query);
    final res = await _dio.get(
      '$baseUrl/?s=$encoded&post_type=wp-manga&page=$page',
    );
    return _parseMangaList(res.data.toString());
  }

  // ─── HTML parsers ────────────────────────────────────────────

  List<Manga> _parseMangaList(String body) {
    final doc = html_parser.parse(body);
    final results = <Manga>[];

    // Madara uses different item containers across versions
    List<Element> items = [];
    for (final sel in [
      '.page-item-detail',
      '.c-tabs-item__content',
      '.manga-item',
      '.col-6.col-md-3.col-sm-4',
    ]) {
      items = doc.querySelectorAll(sel);
      if (items.isNotEmpty) break;
    }

    for (final item in items) {
      try {
        final linkEl = item.querySelector('.post-title a') ??
            item.querySelector('h3 a') ??
            item.querySelector('h5 a') ??
            item.querySelector('a');
        if (linkEl == null) continue;

        final title = linkEl.text.trim();
        final url = linkEl.attributes['href'] ?? '';
        if (title.isEmpty || url.isEmpty) continue;

        final imgEl = item.querySelector('img');
        String cover = imgEl?.attributes['data-src'] ??
            imgEl?.attributes['src'] ??
            '';
        if (cover.startsWith('//')) cover = 'https:$cover';

        results.add(Manga(
          id: '${id}_${_slugFromUrl(url)}',
          title: title,
          coverUrl: cover,
          url: url,
          sourceId: id,
        ));
      } catch (_) {
        continue;
      }
    }
    return results;
  }

  // ─── Manga Detail ────────────────────────────────────────────

  @override
  Future<Manga> getMangaDetail(Manga manga) async {
    final res = await _dio.get(manga.url);
    final doc = html_parser.parse(res.data.toString());

    final imgEl = doc.querySelector('.summary_image img') ??
        doc.querySelector('.tab-summary img');
    String cover = imgEl?.attributes['data-src'] ??
        imgEl?.attributes['src'] ??
        manga.coverUrl;
    if (cover.startsWith('//')) cover = 'https:$cover';

    final descEl = doc.querySelector('.summary__content p') ??
        doc.querySelector('.summary__content') ??
        doc.querySelector('[class*="description"]');
    final description = descEl?.text.trim();

    final genreEls = [
      ...doc.querySelectorAll('.genres-content a'),
      ...doc.querySelectorAll('.mg_genres .summary-content a'),
    ];
    final genres = genreEls.map((e) => e.text.trim()).toList();

    final statusEl = doc.querySelector(
            '.post-status .summary-content:last-child') ??
        doc.querySelector('.mg_status .summary-content');
    final status = statusEl?.text.trim();

    final authorEl = doc.querySelector('.author-content a') ??
        doc.querySelector('.mg_author .summary-content');
    final author = authorEl?.text.trim();

    return manga.copyWith(
      coverUrl: cover,
      description: description,
      genres: genres,
      status: status,
      author: author,
    );
  }

  // ─── Chapters ────────────────────────────────────────────────

  @override
  Future<List<Chapter>> getChapters(Manga manga) async {
    final res = await _dio.get(manga.url);
    final body = res.data.toString();

    // Try AJAX if the page embeds a post ID
    final postIdMatch =
        RegExp(r"(?:manga_id|\"manga\"|'manga')\s*[=:]\s*['\"]?(\d+)")
            .firstMatch(body);
    if (postIdMatch != null) {
      try {
        final ajaxRes = await _dio.post(
          '$baseUrl/wp-admin/admin-ajax.php',
          data: {
            'action': 'manga_get_chapters',
            'manga': postIdMatch.group(1),
          },
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        final chapters = _parseChapters(ajaxRes.data.toString(), manga.id);
        if (chapters.isNotEmpty) return chapters;
      } catch (_) {}
    }

    return _parseChapters(body, manga.id);
  }

  List<Chapter> _parseChapters(String body, String mangaId) {
    final doc = html_parser.parse(body);
    final chapters = <Chapter>[];

    final chEls = [
      ...doc.querySelectorAll('.wp-manga-chapter'),
      ...doc.querySelectorAll('.chapter-manhwa-book-item'),
      ...doc.querySelectorAll('li.a-h'),
    ];

    for (final el in chEls) {
      try {
        final linkEl = el.querySelector('a');
        if (linkEl == null) continue;
        final title = linkEl.text.trim();
        final url = linkEl.attributes['href'] ?? '';
        if (url.isEmpty) continue;

        double? number;
        final m = RegExp(r'(\d+\.?\d*)').firstMatch(title);
        if (m != null) number = double.tryParse(m.group(1)!);

        final dateEl = el.querySelector('.chapter-release-date') ??
            el.querySelector('.release-content');
        DateTime? uploadedAt;
        if (dateEl != null) uploadedAt = _parseDate(dateEl.text.trim());

        chapters.add(Chapter(
          id: '${mangaId}_${_slugFromUrl(url)}',
          title: title,
          url: url,
          mangaId: mangaId,
          number: number,
          uploadedAt: uploadedAt,
        ));
      } catch (_) {
        continue;
      }
    }
    return chapters;
  }

  // ─── Chapter Pages ───────────────────────────────────────────

  @override
  Future<List<String>> getChapterPages(Chapter chapter) async {
    final res = await _dio.get(chapter.url);
    final doc = html_parser.parse(res.data.toString());
    final pages = <String>[];

    var imgEls = [
      ...doc.querySelectorAll('.reading-content img'),
      ...doc.querySelectorAll('.page-break img'),
    ];

    if (imgEls.isEmpty) {
      imgEls = doc.querySelectorAll('img[data-src]');
    }

    for (final img in imgEls) {
      String src = img.attributes['data-src'] ??
          img.attributes['src'] ??
          '';
      src = src.trim();
      if (src.isEmpty) continue;
      // Skip site assets
      if (src.contains('logo') ||
          src.contains('avatar') ||
          src.contains('icon')) continue;
      if (src.startsWith('//')) src = 'https:$src';
      pages.add(src);
    }
    return pages;
  }

  // ─── Helpers ─────────────────────────────────────────────────

  String _slugFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url.hashCode.toString();
    final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.last : url.hashCode.toString();
  }

  DateTime? _parseDate(String text) {
    try {
      return DateTime.parse(text);
    } catch (_) {
      return null;
    }
  }
}
