import 'package:flutter/material.dart';
import 'package:flutter_app/database_helper.dart';
import 'dart:io';

class AnalysisRecord {
  final int id;
  final int age;
  final String gender;
  final String emotion;
  final String race;
  final String timestamp;
  final String imagePath;

  AnalysisRecord({required this.id, required this.age, required this.gender, required this.emotion, required this.race, required this.timestamp, required this.imagePath});

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

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<AnalysisRecord>> _historyFuture;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = dbHelper.queryAllRows().then((rows) => rows.map((row) => AnalysisRecord.fromMap(row)).toList());
    });
  }

  // Kayıt Silme Fonksiyonu
  void _deleteRecord(int id) async {
    await dbHelper.delete(id);
    // Not: _loadHistory() çağırmaya gerek yok çünkü Dismissible görsel olarak satırı zaten uçuruyor.
    // Ancak veritabanı tutarlılığı için listeyi güncellemek iyi olabilir veya
    // setState içinde listeyi manuel güncelleyebiliriz. Basitlik adına burada bırakalım.
    
    // Eğer kullanıcı çok hızlı silerse snackbar üst üste binmesin diye öncekini gizle
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt silindi'), duration: Duration(seconds: 2), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ... (Yardımcı fonksiyonlar: _formatDate, _formatTime, _getEmotionColor, _translateRace AYNI KALSIN) ...
  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return "${dt.day}.${dt.month}.${dt.year}";
    } catch (e) { return ""; }
  }
  
  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
    } catch (e) { return ""; }
  }

  Color _getEmotionColor(String emotion) {
    switch(emotion.toLowerCase()) {
      case 'happy': return Colors.green;
      case 'sad': return Colors.blueGrey;
      case 'angry': return Colors.red;
      case 'fear': return Colors.purple;
      case 'surprise': return Colors.orange;
      default: return Colors.deepPurple;
    }
  }

  String _translateRace(String race) {
    if (race.isEmpty) return "";
    switch(race.toLowerCase()) {
      case 'white': return 'Beyaz';
      case 'latino hispanic': return 'Latin / Hispanik';
      case 'asian': return 'Asyalı';
      case 'middle eastern': return 'Orta Doğulu';
      case 'indian': return 'Hint';
      case 'black': return 'Siyahi';
      default: return race.length > 1 ? race[0].toUpperCase() + race.substring(1) : race;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Geçmiş Analizler", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: FutureBuilder<List<AnalysisRecord>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("Henüz kayıt yok", style: TextStyle(color: Colors.grey[500], fontSize: 18)),
                ],
              ),
            );
          }

          final records = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final emotionColor = _getEmotionColor(record.emotion);

              // *** YENİ KISIM: DISMISSIBLE ***
              return Dismissible(
                // Her satır için benzersiz bir anahtar (ID) gereklidir
                key: Key(record.id.toString()),
                
                // Sadece sağdan sola kaydırarak silme (genel standart)
                direction: DismissDirection.endToStart,
                
                // Kaydırınca arkada çıkan kırmızı alan
                background: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 25),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("SİL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.delete_outline, color: Colors.white, size: 30),
                    ],
                  ),
                ),
                
                // Kullanıcı kaydırdığında silinsin mi diye soralım
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Silinsin mi?"),
                      content: const Text("Bu analiz kalıcı olarak silinecek."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                },
                
                // Onay verilirse burası çalışır ve veritabanından siler
                onDismissed: (direction) {
                  _deleteRecord(record.id);
                  // Listeden anlık olarak veriyi kaldırmamız lazım ki hata vermesin
                  setState(() {
                    records.removeAt(index);
                  });
                },

                // Asıl Kart Tasarımı
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                    border: Border(left: BorderSide(color: emotionColor, width: 5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Fotoğraf
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(record.imagePath),
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 75, height: 75, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Bilgiler
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("${record.age} Yaş", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  Text(record.gender == 'Man' ? 'Erkek' : 'Kadın', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 10,
                                runSpacing: 4,
                                children: [
                                  _buildTag("Duygu: ${record.emotion}", emotionColor.withOpacity(0.1), emotionColor),
                                  _buildTag(_translateRace(record.race), Colors.blueGrey.withOpacity(0.1), Colors.blueGrey),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text("${_formatDate(record.timestamp)} • ${_formatTime(record.timestamp)}", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}