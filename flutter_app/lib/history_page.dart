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
      _historyFuture = dbHelper.queryAllRows().then((rows) => rows.map((row) => AnalysisRecord.fromMap(row)).toList()); // En yeniyi en üste al
    });
  }

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

  // Duyguya göre kart kenar rengi belirleme
  Color _getEmotionColor(String emotion) {
    switch(emotion.toLowerCase()) {
      case 'happy': return Colors.green;
      case 'sad': return Colors.blueGrey;
      case 'angry': return Colors.red;
      default: return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Geçmiş Analizler", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
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

              return Container(
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
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
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
                                Text(record.gender == 'Man' ? 'Erkek' : 'Kadın', style: TextStyle(color: Colors.grey[700])),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Duygu: ${record.emotion}", 
                              style: TextStyle(color: emotionColor, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
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
              );
            },
          );
        },
      ),
    );
  }
}