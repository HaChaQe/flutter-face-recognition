# 📸 AI Powered Face Analysis App

Flutter ve Python (FastAPI) kullanılarak geliştirilmiş, anlık duygu, yaş, ırk ve cinsiyet analizi yapan full-stack mobil uygulama.

## 🚀 Proje Hakkında

Bu proje, mobil tarafta kullanıcıdan alınan görsel verisinin, sunucu tarafında Yapay Zeka (DeepFace) kütüphanesi ile işlenip sonuçların asenkron olarak kullanıcıya sunulmasını amaçlar.

**Öne Çıkan Özellikler:**
* 🖼️ **Multipart Request:** Görseller API'ye Base64 yerine `multipart/form-data` olarak, profesyonel standartlarda iletilir.
* ⚡ **Asenkron Mimari:** FastAPI backend'i, Flutter'dan gelen eş zamanlı istekleri bloklamadan (non-blocking) işler.
* 🔄 **Backend-Frontend Entegrasyonu:** Dio paketi kullanılarak stabil bir veri akışı sağlanmıştır.
* 🧠 **Deep Learning:** DeepFace kütüphanesi ile yüksek doğruluklu yüz analizi.

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
