-- V20: Create GopYPhanAnh table for Feedback feature
CREATE TABLE IF NOT EXISTS "GopYPhanAnh" (
    id SERIAL PRIMARY KEY,
    magopy VARCHAR(50) NOT NULL DEFAULT '',
    cccd VARCHAR(12),
    zaloid VARCHAR(100),
    loaigopy INT NOT NULL DEFAULT 1,
    tieude VARCHAR(200) NOT NULL,
    noidung TEXT NOT NULL,
    filedinhkem JSONB,
    hosoid INT,
    trangthai INT NOT NULL DEFAULT 0,
    douutien INT DEFAULT 0,
    nhanvienxulyid INT,
    ghichunoibo TEXT,
    ngaytao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngayxuly TIMESTAMP,
    ngayhoanthanh TIMESTAMP,
    danhgia INT,
    phanhoidanhgia TEXT
);
COMMENT ON TABLE "GopYPhanAnh" IS 'Góp ý, khiếu nại, khen ngợi từ công dân';