import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manga_providers.dart';
import '../widgets/manga_card.dart';
import '../theme/app_theme.dart';
import 'manga_detail_screen.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(sourceManagerProvider).all;
    final selIdx = ref.watch(selectedSourceIndexProvider);
    final mode = ref.watch(browseModeProvider);
    final mangaList = ref.watch(mangaListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن مانجا...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                ),
                onSubmitted: (q) =>
                    ref.read(searchQueryProvider.notifier).state = q.trim(),
              )
            : const Text('Smanga'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _searching
                ? _clearSearch
                : () => setState(() => _searching = true),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_searching ? 52 : 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source chips
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: sources.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: ChoiceChip(
                      label: Text(sources[i].name),
                      selected: selIdx == i,
                      onSelected: (_) {
                        ref
                            .read(selectedSourceIndexProvider.notifier)
                            .state = i;
                        _clearSearch();
                      },
                    ),
                  ),
                ),
              ),
              // Popular / Latest toggle
              if (!_searching)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 6),
                  child: Row(children: [
                    _modeBtn(BrowseMode.popular, 'الأكثر شهرة'),
                    _modeBtn(BrowseMode.latest, 'آخر الإصدارات'),
                  ]),
                ),
            ],
          ),
        ),
      ),
      body: mangaList.when(
        data: (list) => list.isEmpty
            ? const _EmptyState(message: 'لا توجد نتائج')
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => MangaCard(
                  manga: list[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MangaDetailScreen(manga: list[i]),
                    ),
                  ),
                ),
              ),
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 8,
          itemBuilder: (_, __) => const MangaCardSkeleton(),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: AppTheme.primary, size: 52),
              const SizedBox(height: 16),
              const Text('تعذّر الاتصال بالمصدر',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
              const SizedBox(height: 8),
              Text('$e',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(mangaListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeBtn(BrowseMode bMode, String label) {
    final current = ref.watch(browseModeProvider);
    return TextButton(
      onPressed: () => ref.read(browseModeProvider.notifier).state = bMode,
      style: TextButton.styleFrom(
        foregroundColor: current == bMode
            ? AppTheme.primary
            : AppTheme.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(label,
          style: TextStyle(
              fontWeight: current == bMode
                  ? FontWeight.bold
                  : FontWeight.normal)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
    );
  }
}
