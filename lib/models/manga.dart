class Manga {
  final String id;
  final String title;
  final String coverUrl;
  final String url;
  final String sourceId;
  final String? description;
  final List<String> genres;
  final String? status;
  final String? author;
  bool isBookmarked;

  Manga({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.url,
    required this.sourceId,
    this.description,
    this.genres = const [],
    this.status,
    this.author,
    this.isBookmarked = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'coverUrl': coverUrl,
        'url': url,
        'sourceId': sourceId,
        'description': description,
        'genres': genres.join(','),
        'status': status,
        'author': author,
        'isBookmarked': isBookmarked ? 1 : 0,
      };

  factory Manga.fromMap(Map<String, dynamic> map) => Manga(
        id: map['id'] as String,
        title: map['title'] as String,
        coverUrl: map['coverUrl'] as String,
        url: map['url'] as String,
        sourceId: map['sourceId'] as String,
        description: map['description'] as String?,
        genres: (map['genres'] as String?)
                ?.split(',')
                .where((s) => s.isNotEmpty)
                .toList() ??
            [],
        status: map['status'] as String?,
        author: map['author'] as String?,
        isBookmarked: (map['isBookmarked'] as int?) == 1,
      );

  Manga copyWith({
    String? title,
    String? coverUrl,
    String? description,
    List<String>? genres,
    String? status,
    String? author,
    bool? isBookmarked,
  }) =>
      Manga(
        id: id,
        title: title ?? this.title,
        coverUrl: coverUrl ?? this.coverUrl,
        url: url,
        sourceId: sourceId,
        description: description ?? this.description,
        genres: genres ?? this.genres,
        status: status ?? this.status,
        author: author ?? this.author,
        isBookmarked: isBookmarked ?? this.isBookmarked,
      );
}
