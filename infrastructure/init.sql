CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE TYPE parcel_status AS ENUM ('pending_verification', 'ready_for_pickup', 'claimed');
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nim VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    telegram_chat_id VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE parcels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parcel_number VARCHAR(20) UNIQUE NOT NULL, 
    recipient_name_ocr VARCHAR(150) NOT NULL,  
    matched_student_id UUID REFERENCES students(id) ON DELETE SET NULL,
    category CHAR(1) NOT NULL CHECK (category IN ('A', 'B', 'C', 'D', 'E')),
    status parcel_status DEFAULT 'pending_verification',
    photo_url TEXT,
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    picked_up_at TIMESTAMP
);
CREATE INDEX idx_students_name_trgm ON students USING gist (full_name gist_trgm_ops);
CREATE INDEX idx_parcels_status ON parcels(status);
CREATE OR REPLACE FUNCTION find_closest_student(ocr_name TEXT)
RETURNS TABLE(student_id UUID, student_name VARCHAR, similarity_score REAL) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        id AS student_id, 
        full_name AS student_name, 
        similarity(full_name, ocr_name) AS similarity_score
    FROM students
    WHERE similarity(full_name, ocr_name) > 0.3 
    ORDER BY similarity_score DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;
