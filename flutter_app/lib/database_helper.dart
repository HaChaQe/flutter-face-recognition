import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static const _databaseName = "AnalysisHistory.db";
  static const _databaseVersion = 1;

  static const table = 'analyses';

  static const columnId = 'id';
  static const columnAge = 'age';
  static const columnGender = 'gender';
  static const columnEmotion = 'emotion';
  static const columnRace = 'race';
  static const columnTimestamp = 'timestamp';
  static const columnImagePath = "image_path";

  // Bu sınıfı 'singleton' yapıyoruz (her zaman tek bir örneği olacak)
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Veritabanını diske kaydetmek için yolu belirler
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // Veritabanı ilk kez oluşturulduğunda çalışacak SQL komutu
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnAge INTEGER NOT NULL,
        $columnGender TEXT NOT NULL,
        $columnEmotion TEXT NOT NULL,
        $columnRace TEXT NOT NULL,
        $columnTimestamp TEXT NOT NULL,
        $columnImagePath TEXT NOT NULL
      )
      ''');
  }

  // VERİ EKLEME (INSERT) METODU
  // Kayıt için Map<String, dynamic> tipinde bir veri alır
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  //VERİ SİLME (DELETE) METODU
  Future<void> delete(int id) async {
    Database db = await instance.database;
    await db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Tüm kayıtları okuma (SELECT *) metodu (Bunu bir sonraki adımda kullanacağız)
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table, orderBy: "$columnTimestamp DESC"); // En yeniden eskiye sırala
  }
}