import 'package:flutter/material.dart';
import 'package:flutter_app/database_helper.dart'; // Proje adınız farklıysa 'database_helper.dart' olarak düzeltin
import 'dart:io';

// Veritabanından okuduğumuz veriyi tutacak model sınıfı
class AnalysisRecord {
  final int id;
  final int age;
  final String gender;
  final String emotion;
  final String race;
  final String timestamp; // Bu, veritabanında sakladığımız ISO string formatındaki tarih
  final String imagePath;

  AnalysisRecord({
    required this.id,
    required this.age,
    required this.gender,
    required this.emotion,
    required this.race,
    required this.timestamp,
    required this.imagePath
  });

  // Veritabanından gelen Map'i (satırı) bir objeye dönüştürür
  factory AnalysisRecord.fromMap(Map<String, dynamic> map) {
    return AnalysisRecord(
      id: map[DatabaseHelper.columnId],
      age: map[DatabaseHelper.columnAge],
      gender: map[DatabaseHelper.columnGender],
      emotion: map[DatabaseHelper.columnEmotion],
      race: map[DatabaseHelper.columnRace],
      timestamp: map[DatabaseHelper.columnTimestamp],
      imagePath: map[DatabaseHelper.columnImagePath],
    );
  }
}

// Geçmiş sayfasının kendisi
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Veritabanından gelecek veriyi tutacak olan 'Future'
  late Future<List<AnalysisRecord>> _historyFuture;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    // Sayfa açılır açılmaz veritabanından verileri çekmeyi başlat
    _loadHistory();
  }

  // Veritabanından tüm kayıtları çeken ve state'i güncelleyen metod
  void _loadHistory() {
    setState(() {
      _historyFuture = dbHelper.queryAllRows().then(
        // Gelen her bir Map satırını AnalysisRecord objesine dönüştür
        (rows) => rows.map((row) => AnalysisRecord.fromMap(row)).toList()
      );
    });
  }

  // ISO formatındaki tarihi (örn: "2025-11-02T19:30:15...")
  // "02.11.2025 - 19:30" gibi okunabilir bir formata çevirir
  String _formatTimestamp(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      // Saati ve dakikayı 2 haneli (09:05 gibi) göstermek için padLeft
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');

      return "${dt.day}.${dt.month}.${dt.year} - $hour:$minute";
    } catch (e) {
      return isoString; // Hata olursa orijinal metni göster
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Geçmiş Analizler"),
      ),
      // FutureBuilder: Asenkron (veritabanı) işlemleri için mükemmel bir widget
      body: FutureBuilder<List<AnalysisRecord>>(
        future: _historyFuture, // Hangi 'future'ı dinleyeceği
        builder: (context, snapshot) {

          // 1. Veri henüz yükleniyorsa...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Bir hata oluştuysa...
          if (snapshot.hasError) {
            return Center(child: Text("Veriler yüklenirken hata oluştu: ${snapshot.error}"));
          }

          // 3. Veri geldi ama boşsa (veya hiç yoksa)...
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Henüz kaydedilmiş bir analiz bulunmuyor.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // 4. Veri başarıyla geldiyse, listeyi göster
          final records = snapshot.data!;
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];

              // Her bir kayıt için güzel bir liste elemanı oluştur
              // ESKİ Card VE ListTile BLOĞUNU SİL, BUNU YAPIŞTIR
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(

                  // Yaş dairesi (CircleAvatar) yerine fotoğrafı gösteriyoruz
                  leading: ClipRRect( // Köşeleri yuvarlatmak için
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(record.imagePath), // Veritabanından gelen yoldaki dosyayı yükle
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover, // Resmi sığdır/kırp

                      // Hata olursa (dosya silinirse vb.) bir ikon göster
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  title: Text.rich(
                  TextSpan(
                    // Varsayılan stil (etiketler için)
                    style: const TextStyle(
                      fontWeight: FontWeight.w500, // Kalın (medium)
                      fontSize: 15,
                      color: Colors.black87, // Rengi de belirleyelim
                    ),
                    children: [
                      const TextSpan(text: "Yaş: "),
                      TextSpan(
                        text: "${record.age}\n", // Veri
                        style: const TextStyle(fontWeight: FontWeight.normal), // Kalınlığı sıfırla
                      ),
                      
                      const TextSpan(text: "Cinsiyet: "),
                      TextSpan(
                        text: "${record.gender}\n", // Veri
                        style: const TextStyle(fontWeight: FontWeight.normal), // Kalınlığı sıfırla
                      ),

                      const TextSpan(text: "İfade: "),
                      TextSpan(
                        text: "${record.emotion}\n", // Veri
                        style: const TextStyle(fontWeight: FontWeight.normal), // Kalınlığı sıfırla
                      ),

                      const TextSpan(text: "Baskın Irk: "),
                      TextSpan(
                        text: "${record.race}", // Veri
                        style: const TextStyle(fontWeight: FontWeight.normal), // Kalınlığı sıfırla
                      ),
                    ],
                  ),
                ),
                
                subtitle: Text(
                  _formatTimestamp(record.timestamp), 
                ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}