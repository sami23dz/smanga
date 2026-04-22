class Chapter {
  final String id;
  final String title;
  final String url;
  final String mangaId;
  final double? number;
  final DateTime? uploadedAt;
  bool isDownloaded;
  List<String> localPages;

  Chapter({
    required this.id,
    required this.title,
    required this.url,
    required this.mangaId,
    this.number,
    this.uploadedAt,
    this.isDownloaded = false,
    this.localPages = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'mangaId': mangaId,
        'number': number,
        'uploadedAt': uploadedAt?.millisecondsSinceEpoch,
        'isDownloaded': isDownloaded ? 1 : 0,
        'localPages': localPages.join('|'),
      };

  factory Chapter.fromMap(Map<String, dynamic> map) => Chapter(
        id: map['id'] as String,
        title: map['title'] as String,
        url: map['url'] as String,
        mangaId: map['mangaId'] as String,
        number: map['number'] != null ? (map['number'] as num).toDouble() : null,
        uploadedAt: map['uploadedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['uploadedAt'] as int)
            : null,
        isDownloaded: (map['isDownloaded'] as int?) == 1,
        localPages: (map['localPages'] as String?)
                ?.split('|')
                .where((s) => s.isNotEmpty)
                .toList() ??
            [],
      );
}
