-- V19: Allow counter_id to be NULL in application_history table
-- For citizen booking via Mini App without counter assignment
ALTER TABLE application_history
ALTER COLUMN counter_id DROP NOT NULL;
-- Also update GopYPhanAnh table if not exists (for Feedback feature)
-- If the table doesn't exist, create it
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_name = 'gopyphananh'
) THEN CREATE TABLE GopYPhanAnh (
    Id SERIAL PRIMARY KEY,
    MaGopY VARCHAR(50) NOT NULL DEFAULT '',
    CCCD VARCHAR(12),
    ZaloId VARCHAR(100),
    LoaiGopY INT NOT NULL DEFAULT 1,
    TieuDe VARCHAR(200) NOT NULL,
    NoiDung TEXT NOT NULL,
    FileDinhKem JSONB,
    HoSoId INT,
    TrangThai INT NOT NULL DEFAULT 0,
    DoUuTien INT DEFAULT 0,
    NhanVienXuLyId INT,
    GhiChuNoiBo TEXT,
    NgayTao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    NgayXuLy TIMESTAMP,
    NgayHoanThanh TIMESTAMP,
    DanhGia INT,
    PhanHoiDanhGia TEXT
);
COMMENT ON TABLE GopYPhanAnh IS 'Góp ý, khiếu nại, khen ngợi từ công dân';
END IF;
END $$;