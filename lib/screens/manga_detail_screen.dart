import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import '../providers/manga_providers.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'reader_screen.dart';

class MangaDetailScreen extends ConsumerStatefulWidget {
  final Manga manga;
  const MangaDetailScreen({super.key, required this.manga});

  @override
  ConsumerState<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends ConsumerState<MangaDetailScreen> {
  bool _bookmarked = false;
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _db.isBookmarked(widget.manga.id).then((v) {
      if (mounted) setState(() => _bookmarked = v);
    });
  }

  Future<void> _toggleBookmark(Manga manga) async {
    if (_bookmarked) {
      await _db.removeBookmark(manga.id);
    } else {
      await _db.bookmarkManga(manga);
    }
    setState(() => _bookmarked = !_bookmarked);
    ref.invalidate(libraryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(mangaDetailProvider(widget.manga));
    final chaptersAsync = ref.watch(chaptersProvider(widget.manga));

    return Scaffold(
      body: detailAsync.when(
        data: (m) => _body(context, m, chaptersAsync),
        loading: () => _body(context, widget.manga, chaptersAsync),
        error: (_, __) => _body(context, widget.manga, chaptersAsync),
      ),
    );
  }

  Widget _body(BuildContext ctx, Manga m,
      AsyncValue<List<Chapter>> chaptersAsync) {
    return CustomScrollView(
      slivers: [
        // ── Collapsible cover app bar ──────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: m.coverUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: AppTheme.card),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.background.withOpacity(0.95),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 16,
                  right: 56,
                  child: Text(
                    m.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(blurRadius: 4, color: Colors.black54)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _bookmarked ? AppTheme.primary : Colors.white,
              ),
              onPressed: () => _toggleBookmark(m),
            ),
          ],
        ),

        // ── Info section ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + author
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (m.status != null)
                      _badge(m.status!, AppTheme.primary),
                    if (m.author != null)
                      Text(m.author!,
                          style: const TextStyle(
                              color: AppTheme.textSecondary)),
                  ],
                ),

                // Genres
                if (m.genres.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: m.genres
                        .map((g) => _badge(g, AppTheme.card,
                            textColor: AppTheme.textSecondary))
                        .toList(),
                  ),
                ],

                // Description
                if (m.description != null) ...[
                  const SizedBox(height: 16),
                  const Text('القصة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(m.description!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, height: 1.55)),
                ],

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Text('الفصول',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ),

        // ── Chapters ───────────────────────────────────────────
        chaptersAsync.when(
          data: (chapters) => chapters.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text('لا توجد فصول',
                            style:
                                TextStyle(color: AppTheme.textSecondary))),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ChapterTile(chapter: chapters[i], manga: m),
                    childCount: chapters.length,
                  ),
                ),
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child:
                  Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                  child: Text('خطأ في تحميل الفصول: $e',
                      style:
                          const TextStyle(color: AppTheme.textSecondary))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String label, Color bg,
      {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg.withOpacity(0.4)),
      ),
      child:
          Text(label, style: TextStyle(color: textColor, fontSize: 12)),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final Manga manga;
  const _ChapterTile({required this.chapter, required this.manga});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(chapter.title,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      subtitle: chapter.uploadedAt != null
          ? Text(_fmt(chapter.uploadedAt!),
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11))
          : null,
      trailing: chapter.isDownloaded
          ? const Icon(Icons.download_done,
              color: AppTheme.primary, size: 18)
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReaderScreen(chapter: chapter, manga: manga),
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
