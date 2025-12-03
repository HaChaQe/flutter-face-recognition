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

  FaceAnalysisResult({this.age, this.gender, this.dominantEmotion, this.dominantRace});
 
 //FastAPIden gelen JSONu objeye çevirir
  factory FaceAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FaceAnalysisResult(
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      dominantEmotion: json['dominant_emotion'] as String?,
      dominantRace: json['dominant_race'] as String?,
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

  //SONUÇ EKRANI (ModalBottomSheet)
  void _showResultSheet(FaceAnalysisResult result) {
    final emotionData = _getEmotionData(result.dominantEmotion);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 450,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50, height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Analiz Sonuçları", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Sonuç Kartları Grid Yapısı
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildInfoCard(
                      title: "Yaş",
                      value: "${result.age}",
                      icon: Icons.cake,
                      color: Colors.blueAccent,
                    ),
                    _buildInfoCard(
                      title: "Cinsiyet",
                      value: _translateGender(result.gender),
                      icon: _getGenderIcon(result.gender),
                      color: result.gender == 'Woman' ? Colors.pinkAccent : Colors.blue,
                    ),
                    _buildInfoCard(
                      title: "Duygu",
                      value: emotionData['label'],
                      icon: emotionData['icon'],
                      color: emotionData['color'],
                    ),
                    _buildInfoCard(
                      title: "Irk/Köken",
                      value: result.dominantRace ?? "?",
                      icon: Icons.public,
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Sonucu ve Fotoğrafı Kaydet"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _saveAnalysis(result);
                    Navigator.pop(context);
                  },
                ),
              )
            ],
          ),
        );
      },
    );
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
      setState(() {
        _statusMessage = "Bağlantı hatası: ${e.message}";
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_statusMessage), backgroundColor: Colors.red));
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