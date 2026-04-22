import 'madara_source.dart';

class LekMangaSource extends MadaraSource {
  @override
  String get id => 'lekmanga';

  @override
  String get name => 'LekManga';

  @override
  String get baseUrl => 'https://lekmanga.net';

  @override
  String get iconUrl => 'https://lekmanga.net/favicon.ico';

  @override
  String get language => 'ar';
}
