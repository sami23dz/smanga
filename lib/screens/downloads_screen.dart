import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chapter.dart';
import '../models/manga.dart';
import '../services/database_service.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';
import 'reader_screen.dart';

final _downloadsProvider = FutureProvider<List<Chapter>>((ref) {
  return DatabaseService().getAllDownloadedChapters();
});

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dlAsync = ref.watch(_downloadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التنزيلات')),
      body: dlAsync.when(
        data: (chapters) {
          if (chapters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.download_outlined,
                      size: 72, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text('لا توجد فصول محمّلة',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('افتح فصلاً واضغط زر التنزيل',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          // Group chapters by mangaId
          final Map<String, List<Chapter>> grouped = {};
          for (final ch in chapters) {
            grouped.putIfAbsent(ch.mangaId, () => []).add(ch);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: grouped.entries.map((entry) {
              final mangaId = entry.key;
              final chs = entry.value;
              // Derive a display title from the mangaId slug
              final displayTitle =
                  mangaId.replaceAll('_', ' ').split(' ').skip(1).join(' ');

              return _MangaGroup(
                mangaId: mangaId,
                displayTitle: displayTitle,
                chapters: chs,
                onDeleted: () => ref.invalidate(_downloadsProvider),
              );
            }).toList(),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(
          child: Text('خطأ: $e',
              style:
                  const TextStyle(color: AppTheme.textSecondary)),
        ),
      ),
    );
  }
}

class _MangaGroup extends StatelessWidget {
  final String mangaId;
  final String displayTitle;
  final List<Chapter> chapters;
  final VoidCallback onDeleted;

  const _MangaGroup({
    required this.mangaId,
    required this.displayTitle,
    required this.chapters,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            displayTitle.isNotEmpty ? displayTitle : mangaId,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        ...chapters.map((ch) => _ChapterDownloadTile(
              chapter: ch,
              mangaId: mangaId,
              onDeleted: onDeleted,
            )),
        const Divider(height: 1),
      ],
    );
  }
}

class _ChapterDownloadTile extends StatelessWidget {
  final Chapter chapter;
  final String mangaId;
  final VoidCallback onDeleted;

  const _ChapterDownloadTile({
    required this.chapter,
    required this.mangaId,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.download_done,
          color: AppTheme.primary, size: 20),
      title: Text(chapter.title,
          style:
              const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
      subtitle: Text('${chapter.localPages.length} صفحة',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Read button
          IconButton(
            icon: const Icon(Icons.play_arrow,
                color: AppTheme.primary, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReaderScreen(
                  chapter: chapter,
                  manga: Manga(
                    id: mangaId,
                    title: '',
                    coverUrl: '',
                    url: '',
                    sourceId: mangaId.split('_').first,
                  ),
                ),
              ),
            ),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.textSecondary, size: 22),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('حذف التنزيل',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('هل تريد حذف "${chapter.title}"؟',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final manga = Manga(
        id: mangaId,
        title: '',
        coverUrl: '',
        url: '',
        sourceId: mangaId.split('_').first,
      );
      await DownloadService().deleteDownload(manga, chapter);
      onDeleted();
    }
  }
}
