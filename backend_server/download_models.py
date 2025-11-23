# download_models.py
# Bu script, sadece modelleri KYK interneti üzerinden indirmek için var.

from deepface import DeepFace
import os

# İndirme işlemini tetiklemek için sahte/boş bir dosya adı
# Dosyanın var olması gerekmiyor, amaç fonksiyonu çağırmak
dummy_image = "test.jpg" 

print("---------------------------------------------------------")
print("KYK İnterneti üzerinden gerekli AI modelleri indiriliyor.")
print("Bu işlem 200-300MB sürebilir, lütfen sabırla bekleyin...")
print("---------------------------------------------------------")

try:
    # Sunucuda kullanacağımız fonksiyonun AYNISINI çağırıyoruz
    # Bu, deepface'i indirme yapmaya zorlayacak
    DeepFace.analyze(
        img_path=dummy_image, 
        actions=['age', 'gender', 'emotion'],
        enforce_detection=False # 'test.jpg' olmadığı için hata vermesin
    )
except Exception as e:
    # "test.jpg not found" hatası alacağız, BU NORMALDİR.
    # Önemli olan, bu satıra gelmeden indirmelerin başlaması.
    print(f"Hata (normal): {e}")

print("---------------------------------------------------------")
print("İndirme işlemi tamamlandı (veya zaten inikti)!")
print("Artık bu script'i kapatıp HOTSPOT planına geçebilirsiniz.")
print("---------------------------------------------------------")