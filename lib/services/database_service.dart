import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/manga.dart';
import '../models/chapter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'smanga.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE manga (
            id          TEXT PRIMARY KEY,
            title       TEXT NOT NULL,
            coverUrl    TEXT NOT NULL,
            url         TEXT NOT NULL,
            sourceId    TEXT NOT NULL,
            description TEXT,
            genres      TEXT,
            status      TEXT,
            author      TEXT,
            isBookmarked INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE chapters (
            id          TEXT PRIMARY KEY,
            title       TEXT NOT NULL,
            url         TEXT NOT NULL,
            mangaId     TEXT NOT NULL,
            number      REAL,
            uploadedAt  INTEGER,
            isDownloaded INTEGER DEFAULT 0,
            localPages  TEXT DEFAULT '',
            FOREIGN KEY (mangaId) REFERENCES manga(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE reading_progress (
            chapterId TEXT PRIMARY KEY,
            mangaId   TEXT NOT NULL,
            pageIndex INTEGER DEFAULT 0,
            updatedAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ─── Bookmarks ───────────────────────────────────────────────

  Future<void> bookmarkManga(Manga manga) async {
    final db = await database;
    await db.insert(
      'manga',
      {...manga.toMap(), 'isBookmarked': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBookmark(String mangaId) async {
    final db = await database;
    await db.delete('manga', where: 'id = ?', whereArgs: [mangaId]);
  }

  Future<List<Manga>> getBookmarkedManga() async {
    final db = await database;
    final rows = await db.query(
      'manga',
      where: 'isBookmarked = 1',
      orderBy: 'title ASC',
    );
    return rows.map(Manga.fromMap).toList();
  }

  Future<bool> isBookmarked(String mangaId) async {
    final db = await database;
    final rows = await db.query(
      'manga',
      where: 'id = ? AND isBookmarked = 1',
      whereArgs: [mangaId],
    );
    return rows.isNotEmpty;
  }

  // ─── Downloaded chapters ─────────────────────────────────────

  Future<void> saveChapter(Chapter chapter) async {
    final db = await database;
    await db.insert(
      'chapters',
      chapter.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Chapter>> getDownloadedChapters(String mangaId) async {
    final db = await database;
    final rows = await db.query(
      'chapters',
      where: 'mangaId = ? AND isDownloaded = 1',
      whereArgs: [mangaId],
      orderBy: 'number ASC',
    );
    return rows.map(Chapter.fromMap).toList();
  }

  Future<List<Chapter>> getAllDownloadedChapters() async {
    final db = await database;
    final rows = await db.query(
      'chapters',
      where: 'isDownloaded = 1',
      orderBy: 'mangaId ASC, number ASC',
    );
    return rows.map(Chapter.fromMap).toList();
  }

  // ─── Reading progress ────────────────────────────────────────

  Future<void> saveProgress(
      String chapterId, String mangaId, int pageIndex) async {
    final db = await database;
    await db.insert(
      'reading_progress',
      {
        'chapterId': chapterId,
        'mangaId': mangaId,
        'pageIndex': pageIndex,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getProgress(String chapterId) async {
    final db = await database;
    final rows = await db.query(
      'reading_progress',
      where: 'chapterId = ?',
      whereArgs: [chapterId],
    );
    return rows.isNotEmpty ? (rows.first['pageIndex'] as int? ?? 0) : 0;
  }
}
