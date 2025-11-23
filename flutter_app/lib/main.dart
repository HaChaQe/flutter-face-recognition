import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter_app/database_helper.dart';
import 'package:flutter_app/history_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// ÖNEMLİ: Bilgisayarınızın IP adresini buraya yazın
const String YOUR_COMPUTER_IP = "192.168.199.142";
const String SERVER_URL = "http://$YOUR_COMPUTER_IP:8000/analyze";

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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AnalysisPage(),
    );
  }
}

// Yeni veri modelimiz: Analiz sonuçlarını tutacak
class FaceAnalysisResult {
  final int? age;
  final String? gender;
  final String? dominantEmotion;
  final String? dominantRace;

  FaceAnalysisResult({
    this.age,
    this.gender,
    this.dominantEmotion,
    this.dominantRace,
  });

  // JSON'dan FaceAnalysisResult objesine dönüştürme metodu
  factory FaceAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FaceAnalysisResult(
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      dominantEmotion: json['dominant_emotion'] as String?,
      dominantRace: json['dominant_race'] as String?,
    );
  }

  // Map<String, dynamic> toMap() {
  //   return {
  //     // ID'yi null bırakıyoruz, veritabanı otomatik artıracak
  //     DatabaseHelper.columnAge: age,
  //     DatabaseHelper.columnGender: gender,
  //     DatabaseHelper.columnEmotion: dominantEmotion,
  //     DatabaseHelper.columnRace: dominantRace,
  //     DatabaseHelper.columnTimestamp: DateTime.now().toIso8601String(), // Kayıt anını ekliyoruz
  //   };
  // }

  // Pop-up için güzel bir formatlama metodu
  String toDisplayString() {
    return """
Yaş: ${age ?? 'Bilinmiyor'}
Cinsiyet: ${gender ?? 'Bilinmiyor'}
Duygu: ${dominantEmotion ?? 'Bilinmiyor'}
Irk: ${dominantRace ?? 'Bilinmiyor'}
    """;
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
  String _statusMessage = "Analiz etmek için fotoğraf seçin.";
  bool _isLoading = false;
  FaceAnalysisResult? _lastAnalysisResult; // Son analiz sonucunu tutacak

  // Pop-up'ı gösteren metod (GÜNCELLENDİ)
  void _showAnalysisDialog(FaceAnalysisResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yüz Analiz Sonuçları'),
          content: Text(result.toDisplayString()),
          actions: <Widget>[
            // YENİ "KAYDET" BUTONU
            TextButton(
              child: const Text('Kaydet'),
              onPressed: () {
                _saveAnalysis(result);
                Navigator.of(context).pop(); // Pop-up'ı kapat
              },
            ),
            // ESKİ "KAPAT" BUTONU
            TextButton(
              child: const Text('Kapat'),
              onPressed: () {
                Navigator.of(context).pop(); // Pop-up'ı kapat
              },
            ),
          ],
        );
      },
    );
  }

  // 1. YENİ METOT: Galeriden fotoğraf seçer
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Fotoğraf seçildiyse, analiz sürecini başlat
      _startAnalysis(pickedFile);
    }
  }

  Future<void> _openCamera() async {
    // ImagePicker'ı, "Galeri" yerine "Kamera" kaynağıyla çağırıyoruz
    final XFile? takenFile = await _picker.pickImage(
      source: ImageSource.camera, // <-- TEK DEĞİŞİKLİK BURADA
    );

    if (takenFile != null) {
      // Fotoğraf çekildiyse, mevcut analiz sürecini başlat
      _startAnalysis(takenFile);
    }
  }

  // 3. YENİ METOT: Analiz sürecini yürüten ana fonksiyon
  // (Bu, eski _pickAndAnalyzeImage metodundaki try-catch bloğudur)
  Future<void> _startAnalysis(XFile imageFile) async {
    setState(() {
      _imageFile = File(imageFile.path); // Seçilen/Çekilen fotoğrafı ekranda göster
      _isLoading = true;
      _statusMessage = "Analiz ediliyor...";
      _lastAnalysisResult = null;
    });

    try {
      // 2. Fotoğrafı Sunucuya Gönder
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(SERVER_URL, data: formData);

      // 3. Sonucu Al
      if (response.statusCode == 200) {
        final data = response.data;
        final result = FaceAnalysisResult.fromJson(data);

        setState(() {
          _lastAnalysisResult = result;
          _statusMessage = "Analiz Tamamlandı! Fotoğrafa tıklayın.";
        });

      } else {
        setState(() {
          _statusMessage = "Hata: Sunucudan beklenen cevap alınamadı.";
        });
      }
    } on DioException catch (e) {
      String hataMesaji = "Bir hata oluştu: ${e.message}";
      if (e.response != null) {
        hataMesaji = "Hata: ${e.response?.data['detail'] ?? 'Bilinmeyen sunucu hatası'}";
      }
      setState(() {
        _statusMessage = hataMesaji;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAnalysis(FaceAnalysisResult result) async {
    // 1. O an analiz edilen fotoğrafın 'File' objesini al
    final imageFileToSave = _imageFile;
    if (imageFileToSave == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilecek fotoğraf bulunamadı!'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // 2. Fotoğrafı kopyalamak için uygulamanın kalıcı dizinini bul
      final appDir = await getApplicationDocumentsDirectory();

      // 3. Eşsiz bir dosya adı oluştur (örn: 16788865945.jpg)
      // (p.extension: dosya uzantısını alır, örn: ".jpg")
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = p.extension(imageFileToSave.path);
      final newFileName = '$timestamp$fileExtension';

      // 4. Yeni tam dosya yolunu oluştur (örn: /.../app_docs/16788865945.jpg)
      // (p.join: yolları işletim sistemine göre doğru birleştirir)
      final newPath = p.join(appDir.path, newFileName);

      // 5. Fotoğrafı o anki yerinden (galeri/cache) yeni kalıcı yoluna KOPYALA
      final File newImageFile = await imageFileToSave.copy(newPath);

      // 6. Artık hem bilgiyi hem de yeni fotoğrafın yolunu veritabanına kaydet
      final row = {
        DatabaseHelper.columnAge: result.age,
        DatabaseHelper.columnGender: result.gender,
        DatabaseHelper.columnEmotion: result.dominantEmotion,
        DatabaseHelper.columnRace: result.dominantRace,
        DatabaseHelper.columnTimestamp: DateTime.now().toIso8601String(),
        DatabaseHelper.columnImagePath: newImageFile.path // <-- YENİ BİLGİ BURADA
      };

      final id = await dbHelper.insert(row);
      print('Analiz ve fotoğraf kaydedildi, ID: $id, Path: ${newImageFile.path}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analiz ve fotoğraf başarıyla kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Kayıt hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt sırasında hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yüz Analizi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history), // Geçmiş ikonu
            tooltip: "Geçmiş Analizler", // Üzerine basılı tutunca çıkan yazı
            onPressed: () {
              // Tıklayınca HistoryPage'i aç
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
        ]
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Seçilen fotoğrafı göstermek için ve tıklanabilir yaptık
              GestureDetector(
                onTap: () {
                  // Sadece analiz tamamlandıysa pop-up'ı göster
                  if (_lastAnalysisResult != null) {
                    _showAnalysisDialog(_lastAnalysisResult!);
                  }
                },
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _lastAnalysisResult != null ? Colors.green : Colors.blueAccent,
                      width: _lastAnalysisResult != null ? 3 : 1
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 24),

              Column(
                // Butonların genişleyip tüm yatay alanı kaplamasını sağlar
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [
                  // 1. KAMERA BUTONU (Yeniden Stillendirildi)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _openCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Fotoğraf Çek'),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: Theme.of(context).primaryColor, // Ana temaya uygun renk
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.brown.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12), // Daha uzun buton
                      textStyle: const TextStyle(fontSize: 16), // Daha büyük yazı
                    ),
                  ),

                  const SizedBox(height: 12), // İki buton arasına boşluk

                  // 2. GALERİ BUTONU (Yeniden Stillendirildi)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFromGallery,
                    icon: const Icon(Icons.image_search),
                    label: const Text('Galeriden Seç'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      // İkinci butonun farklı görünmesi için (isteğe bağlı)
                      backgroundColor: Colors.amber.shade500, 
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              
              // Durum alanı
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}