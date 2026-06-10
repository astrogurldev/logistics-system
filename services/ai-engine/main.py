import os
from fastapi import FastAPI, UploadFile, File, HTTPException
from transformers import pipeline
from PIL import Image
import io

app = FastAPI(
    title="UNIDA Smart Logistics AI Engine",
    description="Backend Service untuk Klasifikasi Paket Otomatis menggunakan Hugging Face",
    version="1.0.0"
)

# 1. Inisialisasi Model NLP dari Hugging Face
print("Memuat Model AI Hugging Face (Zero-Shot Classification)...")
classifier = pipeline("zero-shot-classification", model="facebook/bart-large-mnli")
print("Model AI Berhasil Dimuat!")

# 2. Definisi Kategori Paket sesuai Standar Gudang UNIDA Gontor
CATEGORIES = [
    "Buku, Dokumen, Paket Tipis, Jam",       # Kategori A
    "Baju, Hijab, Tas, Dompet, Sandal",      # Kategori B
    "Barang Kecil, Skincare, Obat",          # Kategori C
    "Kardus Sedang (Sepatu dkk)",            # Kategori D
    "Kardus Besar, Meja Belajar"             # Kategori E
]

CATEGORY_MAP = {
    "Buku, Dokumen, Paket Tipis, Jam": "A",
    "Baju, Hijab, Tas, Dompet, Sandal": "B",
    "Barang Kecil, Skincare, Obat": "C",
    "Kardus Sedang (Sepatu dkk)": "D",
    "Kardus Besar, Meja Belajar": "E"
}

@app.get("/")
def check_status():
    return {"status": "online", "system": "UNIDA Smart Logistics AI Engine"}

@app.post("/api/v1/classify-package")
async def classify_package(text_input: str):
    if not text_input:
        raise HTTPException(status_code=400, detail="Teks input tidak boleh kosong!")
    
    try:
        ai_result = classifier(text_input, candidate_labels=CATEGORIES)
        top_label = ai_result['labels'][0]
        confidence_score = ai_result['scores'][0]
        
        return {
            "status": "success",
            "input_text": text_input,
            "predicted_category": CATEGORY_MAP[top_label],
            "description": top_label,
            "confidence_score": round(confidence_score, 4)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Engine Error: {str(e)}")