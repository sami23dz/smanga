import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manga_providers.dart';
import '../widgets/manga_card.dart';
import '../theme/app_theme.dart';
import 'manga_detail_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('مكتبتي')),
      body: library.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.bookmark_border,
                        size: 72, color: AppTheme.textSecondary),
                    SizedBox(height: 16),
                    Text('لم تضف أي مانجا بعد',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('اضغط على علامة الحفظ في صفحة أي مانجا',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final m = list[i]..isBookmarked = true;
                  return MangaCard(
                    manga: m,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MangaDetailScreen(manga: m),
                      ),
                    ),
                  );
                },
              ),
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const MangaCardSkeleton(),
        ),
        error: (e, _) => Center(
          child: Text('خطأ: $e',
              style:
                  const TextStyle(color: AppTheme.textSecondary)),
        ),
      ),
    );
  }
}
