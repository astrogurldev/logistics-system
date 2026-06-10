-- 1. Aktifkan Ekstensi untuk Fuzzy Matching (Pencarian Kemiripan Teks)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Buat tipe ENUM kustom untuk Status Paket
CREATE TYPE parcel_status AS ENUM ('pending_verification', 'ready_for_pickup', 'claimed');

-- 3. Buat Tabel Master Data Mahasiswa (Students)
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nim VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    telegram_chat_id VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Buat Tabel Transaksi Paket (Parcels)
CREATE TABLE parcels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_number VARCHAR(20) UNIQUE NOT NULL, -- Contoh format: '2513 C'
    recipient_name_ocr VARCHAR(150) NOT NULL,  -- Nama mentah hasil scan AI
    matched_student_id UUID REFERENCES students(id) ON DELETE SET NULL,
    category CHAR(1) NOT NULL CHECK (category IN ('A', 'B', 'C', 'D', 'E')),
    status parcel_status DEFAULT 'pending_verification',
    photo_url TEXT,
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    picked_up_at TIMESTAMP
);

-- 5. Optimasi Performa: Buat GIST Index pada kolom nama untuk Fuzzy Search super cepat
CREATE INDEX idx_students_name_trgm ON students USING gist (full_name gist_trgm_ops);
CREATE INDEX idx_parcels_status ON parcels(status);

-- 6. Fungsi Otomatis untuk Fuzzy Matching Nama Mahasiswa
CREATE OR REPLACE FUNCTION find_closest_student(ocr_name TEXT)
RETURNS TABLE(student_id UUID, student_name VARCHAR, similarity_score REAL) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        id AS student_id, 
        full_name AS student_name, 
        similarity(full_name, ocr_name) AS similarity_score
    FROM students
    WHERE similarity(full_name, ocr_name) > 0.3 -- Batas toleransi kemiripan (threshold)
    ORDER BY similarity_score DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;