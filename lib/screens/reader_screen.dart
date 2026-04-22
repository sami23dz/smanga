import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import '../providers/manga_providers.dart';
import '../services/database_service.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Chapter chapter;
  final Manga manga;

  const ReaderScreen({
    super.key,
    required this.chapter,
    required this.manga,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PageController _ctrl;
  int _page = 0;
  bool _uiVisible = true;
  bool _downloading = false;
  double _dlProgress = 0;

  final _db = DatabaseService();
  final _dl = DownloadService();

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _restoreProgress();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    final saved = await _db.getProgress(widget.chapter.id);
    if (saved > 0 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ctrl.jumpToPage(saved),
      );
    }
  }

  Future<void> _download(List<String> pages) async {
    setState(() {
      _downloading = true;
      _dlProgress = 0;
    });
    await _dl.downloadChapter(
      widget.manga,
      widget.chapter,
      pages,
      onProgress: (p) {
        if (mounted) setState(() => _dlProgress = p);
      },
    );
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(chapterPagesProvider(widget.chapter));

    return Scaffold(
      backgroundColor: Colors.black,
      body: pagesAsync.when(
        data: (pages) => _reader(pages),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => _error(e),
      ),
    );
  }

  // ─── Reader ───────────────────────────────────────────────────

  Widget _reader(List<String> pages) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _uiVisible = !_uiVisible),
          child: PageView.builder(
            controller: _ctrl,
            itemCount: pages.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              _db.saveProgress(widget.chapter.id, widget.manga.id, i);
            },
            itemBuilder: (_, i) => _pageWidget(pages[i]),
          ),
        ),
        // Top bar
        AnimatedOpacity(
          opacity: _uiVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_uiVisible,
            child: _topBar(pages),
          ),
        ),
        // Bottom bar
        AnimatedOpacity(
          opacity: _uiVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_uiVisible,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _bottomBar(pages.length),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageWidget(String url) {
    final isLocal = url.startsWith('/');
    final provider = isLocal
        ? FileImage(File(url)) as ImageProvider
        : CachedNetworkImageProvider(url,
            headers: {'Referer': widget.manga.url});

    return PhotoView(
      imageProvider: provider,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3.0,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: isLocal
          ? null
          : (_, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? null
                      : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ?? 1),
                  color: AppTheme.primary,
                ),
              ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────

  Widget _topBar(List<String> pages) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                widget.chapter.title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Download button
            if (!widget.chapter.isDownloaded)
              _downloading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: _dlProgress,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download_outlined,
                          color: Colors.white),
                      onPressed: () {
                        final p = ref.read(
                            chapterPagesProvider(widget.chapter));
                        p.whenData((pages) => _download(pages));
                      },
                    ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom bar ───────────────────────────────────────────────

  Widget _bottomBar(int total) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SafeArea(
        child: Row(
          children: [
            Text(
              '${_page + 1} / $total',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: _page.toDouble(),
                min: 0,
                max: (total - 1).toDouble(),
                divisions: total > 1 ? total - 1 : 1,
                activeColor: AppTheme.primary,
                inactiveColor: Colors.white24,
                onChanged: (v) => _ctrl.jumpToPage(v.round()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────────────

  Widget _error(Object e) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.primary, size: 52),
          const SizedBox(height: 16),
          const Text('تعذّر تحميل الصفحات',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text('$e',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(chapterPagesProvider(widget.chapter)),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('إعادة المحاولة'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رجوع',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}
