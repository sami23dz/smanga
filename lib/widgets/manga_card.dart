import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/manga.dart';
import '../theme/app_theme.dart';

class MangaCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback onTap;

  const MangaCard({super.key, required this.manga, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.card,
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: manga.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppTheme.card,
                      highlightColor: AppTheme.surface,
                      child: Container(color: AppTheme.card),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.card,
                      child: const Icon(Icons.broken_image,
                          color: AppTheme.textSecondary, size: 40),
                    ),
                  ),
                  // Bookmark badge
                  if (manga.isBookmarked)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.bookmark,
                          color: AppTheme.primary, size: 20),
                    ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Text(
                manga.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder shown while manga list is loading.
class MangaCardSkeleton extends StatelessWidget {
  const MangaCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.card,
      highlightColor: AppTheme.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.card,
        ),
      ),
    );
  }
}
