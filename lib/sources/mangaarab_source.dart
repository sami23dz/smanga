import 'madara_source.dart';

class MangaArabSource extends MadaraSource {
  @override
  String get id => 'mangaarab';

  @override
  String get name => 'مانجا العرب';

  @override
  String get baseUrl => 'https://mangaarab.com';

  @override
  String get iconUrl => 'https://mangaarab.com/favicon.ico';

  @override
  String get language => 'ar';
}
