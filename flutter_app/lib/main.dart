import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter_app/database_helper.dart';
import 'package:flutter_app/history_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// ÖNEMLİ: IP Adresiniz (Değişirse buradan güncelleyin)
const String computer_ip = "10.212.33.142"; 
const String SERVER_URL = "http://$computer_ip:8000/analyze";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yüz Analiz Projesi',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, 
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.deepPurple),
        ),
      ),
      home: const AnalysisPage(),
    );
  }
}

// Veri Modeli
class FaceAnalysisResult {
  final int? age;
  final String? gender;
  final String? dominantEmotion;
  final String? dominantRace;
  final Map<String, double>? race;

  FaceAnalysisResult({this.age, this.gender, this.dominantEmotion, this.dominantRace, this.race});
 
 //FastAPIden gelen JSONu objeye çevirir
  factory FaceAnalysisResult.fromJson(Map<String, dynamic> json) {
    Map<String, double>? raceData;
    if (json['race'] != null){
      raceData = Map<String, double>.from(json['race'].map((k,v) => MapEntry(k,(v as num).toDouble())));
    }
    return FaceAnalysisResult(
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      dominantEmotion: json['dominant_emotion'] as String?,
      dominantRace: json['dominant_race'] as String?,
      race: raceData
    );
  }
}

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();
  final dbHelper = DatabaseHelper.instance;

  File? _imageFile;
  String _statusMessage = "Analiz için fotoğraf seçin";
  bool _isLoading = false;
  FaceAnalysisResult? _lastAnalysisResult;

  // Yardımcı: İngilizce çıktıları Türkçeye ve İkona çevirir
  Map<String, dynamic> _getEmotionData(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happy': return {'label': 'Mutlu', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.green};
      case 'sad': return {'label': 'Üzgün', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.blueGrey};
      case 'angry': return {'label': 'Kızgın', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.red};
      case 'surprise': return {'label': 'Şaşkın', 'icon': Icons.emoji_people, 'color': Colors.orange};
      case 'fear': return {'label': 'Korkmuş', 'icon': Icons.error_outline, 'color': Colors.purple};
      case 'neutral': return {'label': 'Nötr', 'icon': Icons.sentiment_neutral, 'color': Colors.grey};
      case 'disgust': return {'label': 'Tiksinmiş', 'icon': Icons.sick, 'color': Colors.brown};
      default: return {'label': emotion ?? 'Bilinmiyor', 'icon': Icons.help_outline, 'color': Colors.black};
    }
  }

  IconData _getGenderIcon(String? gender) {
    if (gender == 'Man') return Icons.male;
    if (gender == 'Woman') return Icons.female;
    return Icons.person;
  }

  String _translateGender(String? gender) {
    if (gender == 'Man') return 'Erkek';
    if (gender == 'Woman') return 'Kadın';
    return 'Bilinmiyor';
  }

  // SONUÇ EKRANI
  void _showResultSheet(FaceAnalysisResult result) {
    final emotionData = _getEmotionData(result.dominantEmotion);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Tam ekran hissiyatı ve scroll için
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          // Ekranın %85'ini kaplasın
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
          ),
          child: Column(
            children: [
              // Tutma çubuğu (Handle)
              const SizedBox(height: 12),
              Container(
                width: 60, height: 6,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              
              // Başlık ve İçerik
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text("Analiz Sonuçları", textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87)),
                    const SizedBox(height: 30),

                    // 1. Bölüm: Temel Bilgiler (Yatay Kartlar)
                    Row(
                      children: [
                        Expanded(child: _buildModernInfoCard("Cinsiyet", _translateGender(result.gender), _getGenderIcon(result.gender), result.gender == 'Woman' ? Colors.pinkAccent : Colors.blueAccent)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildModernInfoCard("Yaş", "${result.age}", Icons.cake_rounded, Colors.orangeAccent)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildModernInfoCard("Duygu", emotionData['label'], emotionData['icon'], emotionData['color'])),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Divider(thickness: 1, height: 1),
                    const SizedBox(height: 30),

                    // 2. Bölüm: Detaylı Irk Analizi
                    const Text("Etnik Köken Dağılımı", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 15),
                    
                    _buildRaceBreakdown(result.race),

                    const SizedBox(height: 40),

                    // Kaydet Butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _saveAnalysis(result);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: Colors.deepPurple.withOpacity(0.4),
                        ),
                        child: const Text("Sonuçları Kaydet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Modern Bilgi Kartı Tasarımı
  Widget _buildModernInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Yüzdesel Irk Dağılımı Listesi
  Widget _buildRaceBreakdown(Map<String, double>? raceData) {
    if (raceData == null) return const Text("Detaylı veri bulunamadı.");

    const double threshold = 1.0; // Yüzde 1'in altındakiler Diğer kategorisinde

    Map<String, double> finalData = {};
    double otherSum = 0;

    // Yüzdesel ırk dağılımı
    raceData.forEach((race, percent){

      if(percent <= 0) return; // 0 ve altındaysa gösterme

      if (percent < threshold){
        otherSum += percent;
      }else {
        finalData[race] = percent;
      }
    });

    // Verileri yüksekten düşüğe sırala
    var sortedEntries = finalData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (otherSum > 0){
      sortedEntries.add(MapEntry("Diğer", otherSum));
    }

    // İlk 4-5 tanesini göstermek yeterli olabilir veya hepsini gösterelim
    return Column(
      children: sortedEntries.map((e) {
        // Yüzde değeri
        double percentage = e.value; 
        // 0-1 arası normalize değer (Progress bar için)
        double normalizedValue = percentage / 100;

        Color barColor = e.key == 'Diğer'
          ? Colors.grey 
          : (normalizedValue > 0.5 ? Colors.deepPurple : Colors.deepPurple.shade300);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Irk isimlerini baş harfi büyük olacak şekilde düzenle
                  Text(
                    _translateRace(e.key),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)
                  ),
                  Text("%${percentage.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: normalizedValue,
                  minHeight: 8,
                  backgroundColor: Colors.grey[100],
                  color: barColor
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _translateRace(String raceKey){
    if (raceKey == "Diğer") return "Diğer";

    switch(raceKey.toLowerCase()) {
      case 'white': return 'Beyaz';
      case 'latino hispanic': return 'Latin / Hispanik';
      case 'asian': return 'Asyalı';
      case 'middle eastern': return 'Orta Doğulu';
      case 'indian': return 'Hint';
      case 'black': return 'Siyahi';
      default: return raceKey[0].toUpperCase() + raceKey.substring(1);
    }
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value, style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Fonksiyonlar (Galeri/Kamera/Analiz/Kayıt)
  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);
    if (file != null) _startAnalysis(file);
  }

  Future<void> _startAnalysis(XFile imageFile) async {
    setState(() {
      _imageFile = File(imageFile.path);
      _isLoading = true;
      _statusMessage = "Analiz ediliyor...";
      _lastAnalysisResult = null;
    });

    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      final response = await _dio.post(SERVER_URL, data: formData);

      if (response.statusCode == 200) {
        final result = FaceAnalysisResult.fromJson(response.data);
        setState(() {
          _lastAnalysisResult = result;
          _statusMessage = "Analiz Tamamlandı!";
        });
        // Sonuç geldiği gibi ekranı aç
        _showResultSheet(result);
      }
    } on DioException catch (e) {
      
      if (e.response?.statusCode == 400) {
        // Sunucu 400 hatası (Bad Request) gönderdiyse, bu "Yüz Bulunamadı" demektir.
        setState(() {
          _statusMessage = "⚠️ Yüz tespit edilemedi! Lütfen yüzünüzün net göründüğü bir fotoğraf çekin.";
        });
      } else {
        // Diğer hatalar (İnternet yok, sunucu kapalı vb.)
        setState(() {
          _statusMessage = "Bağlantı hatası. Sunucunun açık ve aynı ağda olduğundan emin olun.";
        });
      }
    } catch (e) {
       setState(() {
        _statusMessage = "Bilinmeyen bir hata oluştu.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAnalysis(FaceAnalysisResult result) async {
    if (_imageFile == null) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = p.join(appDir.path, '$timestamp.jpg');
      await _imageFile!.copy(newPath);

      final row = {
        DatabaseHelper.columnAge: result.age,
        DatabaseHelper.columnGender: result.gender,
        DatabaseHelper.columnEmotion: result.dominantEmotion,
        DatabaseHelper.columnRace: result.dominantRace,
        DatabaseHelper.columnTimestamp: DateTime.now().toIso8601String(),
        DatabaseHelper.columnImagePath: newPath
      };
      await dbHelper.insert(row);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kaydedildi!'), backgroundColor: Colors.green));
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan için hafif gradient
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Özel AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Yüz Analizi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    IconButton(
                      icon: const Icon(Icons.history_rounded, size: 28),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
                    )
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Fotoğraf Alanı
                      GestureDetector(
                        onTap: () {
                          if (_lastAnalysisResult != null) _showResultSheet(_lastAnalysisResult!);
                        },
                        child: Container(
                          height: 350,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _imageFile != null
                                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.grey[400]),
                                          const SizedBox(height: 10),
                                          Text("Fotoğraf Seçin veya Çekin", style: TextStyle(color: Colors.grey[500]))
                                        ],
                                      ),
                                // Yükleniyor Animasyonu
                                if (_isLoading)
                                  Container(
                                    color: Colors.black45,
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),
                      Text(_statusMessage, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 30),

                      // Butonlar
                      Row(
                        children: [
                          Expanded(
                            child: _buildMainButton(
                              icon: Icons.camera_alt_rounded,
                              label: "Kamera",
                              color: Colors.deepPurple,
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildMainButton(
                              icon: Icons.photo_library_rounded,
                              label: "Galeri",
                              color: Colors.orange.shade800,
                              onTap: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}