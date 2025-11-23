# Gerekli kütüphaneleri içe aktar
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import uvicorn
import shutil # Dosya işlemleri için
import os
from deepface import DeepFace

# FastAPI uygulamasını başlat
app = FastAPI(title="Yüz Analiz API")

# Geçici yüklemeler için bir klasör
TEMP_UPLOAD_DIR = "temp_uploads"
os.makedirs(TEMP_UPLOAD_DIR, exist_ok=True)

@app.get("/")
def read_root():
    """ Sunucunun ayakta olup olmadığını kontrol etmek için ana endpoint. """
    return {"message": "Yüz Analiz Sunucusu Aktif"}

@app.post("/analyze")
async def analyze_face(file: UploadFile = File(...)):
    """
    Flutter'dan gelen bir fotoğrafı alır, analiz eder ve sonuçları döndürür.
    """
    
    # Gelen dosyayı geçici olarak diske kaydet
    file_path = os.path.join(TEMP_UPLOAD_DIR, file.filename)
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        print(f"Dosya geçici olarak kaydedildi: {file_path}")

        # DeepFace ile analizi gerçekleştir
        # Sadece yaş, cinsiyet ve duyguyu analiz et
        analysis_result = DeepFace.analyze(
            img_path=file_path, 
            actions=['age', 'gender', 'emotion', 'race'],
            enforce_detection=True # Yüz bulamazsa hata vermesi için
        )
        
        # DeepFace sonucu bir liste içinde döner, biz ilk yüzü alıyoruz
        first_face_result = analysis_result[0]

        # Sadece istediğimiz temiz veriyi seçelim
        # ve
        # JSON'ın anlayabileceği standart Python tiplerine dönüştürelim

        # 'age' (np.float32) -> int (standart tam sayı)
        # 'dominant_gender' (str) -> str (standart metin)
        # 'dominant_emotion' (str) -> str (standart metin)

        response_data = {
            "status": "success",
            "age": int(first_face_result.get("age")), 
            "gender": str(first_face_result.get("dominant_gender")), # 'gender' değil, 'dominant_gender' olmalı
            "dominant_emotion": str(first_face_result.get("dominant_emotion")),
            "dominant_race": str(first_face_result.get("dominant_race"))
        }
        
        return JSONResponse(content=response_data)

    except Exception as e:
        # Hata yönetimi (örn: fotoğrafta yüz bulunamazsa)
        print(f"Hata oluştu: {str(e)}")
        # DeepFace'in "face could not be detected" hatasını yakala
        if "Face could not be detected" in str(e):
             raise HTTPException(
                status_code=400, 
                detail="Fotoğrafta yüz tespit edilemedi."
            )
        # Diğer genel hatalar
        raise HTTPException(
            status_code=500, 
            detail=f"Sunucu hatası: {str(e)}"
        )
        
    finally:
        # Analiz sonrası geçici dosyayı temizle
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f"Geçici dosya silindi: {file_path}")
        
        # Gelen dosya akışını kapat
        await file.close()

# Sunucuyu çalıştırmak için ana blok
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)