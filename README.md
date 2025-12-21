# 📸 AI Powered Face Analysis App

Flutter ve Python (FastAPI) kullanılarak geliştirilmiş, anlık duygu, yaş, ırk ve cinsiyet analizi yapan full-stack mobil uygulama.

## 🚀 Proje Hakkında

Bu proje, mobil tarafta kullanıcıdan alınan görsel verisinin, sunucu tarafında Yapay Zeka (DeepFace) kütüphanesi ile işlenip sonuçların asenkron olarak kullanıcıya sunulmasını amaçlar.

**Öne Çıkan Özellikler:**
* 🖼️ **Multipart Request:** Görseller API'ye Base64 yerine `multipart/form-data` olarak, profesyonel standartlarda iletilir.
* ⚡ **Asenkron Mimari:** FastAPI backend'i, Flutter'dan gelen eş zamanlı istekleri bloklamadan (non-blocking) işler.
* 🔄 **Backend-Frontend Entegrasyonu:** Dio paketi kullanılarak stabil bir veri akışı sağlanmıştır.
* 🧠 **Deep Learning:** DeepFace kütüphanesi ile yüksek doğruluklu yüz analizi.
![1](https://github.com/user-attachments/assets/943a6847-2b2f-4d8d-8774-6d162c54a662)
![2](https://github.com/user-attachments/assets/968daead-c8b2-4f02-b144-db69afa36259)
![3](https://github.com/user-attachments/assets/0bfe965f-9239-4a6f-9f11-47d14e5f0660)
![4](https://github.com/user-attachments/assets/779b2b14-5f6b-4d8d-9e7a-2b67cbca21bd)

<table align="center">
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/943a6847-2b2f-4d8d-8774-6d162c54a662" width="250" />
      <br />
      <b>Analiz Ekranı</b>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/968daead-c8b2-4f02-b144-db69afa36259" width="250" />
      <br />
      <b>Sonuçlar</b>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/0bfe965f-9239-4a6f-9f11-47d14e5f0660" width="250" />
      <br />
      <b>Kamera Modu</b>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/779b2b14-5f6b-4d8d-9e7a-2b67cbca21bd" width="250" />
      <br />
      <b>Geçmiş</b>
    </td>
  </tr>
</table>

## 🛠️ Teknolojiler

* **Mobil (Frontend):** Flutter, Dart, Dio, Image Picker
* **Backend:** Python, FastAPI, Uvicorn
* **AI/ML:** DeepFace, OpenCV, TensorFlow

## ⚙️ Kurulum ve Çalıştırma

Projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyebilirsiniz.

### 1. Backend (Sunucu) Kurulumu

```bash
cd backend_server
pip install -r requirements.txt
# Sunucuyu başlat (Kendi IP adresinizi main.py içinde güncellemeyi unutmayın)
uvicorn main:app --host 0.0.0.0 --port 8000
```
### 2. Mobil Uygulama Kurulumu

Backend sunucusu çalıştıktan sonra, mobil uygulamayı çalıştırmak için:

1.  `flutter_app/lib/main.dart` dosyasını açın ve `baseUrl` değişkenini kendi yerel IP adresinizle güncelleyin.
    ```dart
    // Örnek: final String baseUrl = "[http://192.168.1.35:8000](http://192.168.1.35:8000)";
    ```
2.  Bağımlılıkları yükleyin ve uygulamayı başlatın:

```bash
cd flutter_app
flutter pub get
flutter run
