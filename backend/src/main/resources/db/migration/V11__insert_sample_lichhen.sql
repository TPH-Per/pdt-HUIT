-- =============================================
-- HỆ THỐNG QUẢN LÝ QUẦY - CHỢ LỚN HCMC
-- PostgreSQL Database Migration V11
-- Insert Sample LichHen Data (For Testing Queue)
-- =============================================
-- =============================================
-- CITIZENS: Công dân mẫu để test
-- =============================================
INSERT INTO Citizens (
        CCCD,
        HoTen,
        NgaySinh,
        GioiTinh,
        DiaChiThuongTru,
        SoDienThoai,
        Email
    )
VALUES (
        '079100000001',
        'Nguyễn Văn An',
        '1990-05-15',
        'Nam',
        '123 Nguyễn Huệ, Q1, TP.HCM',
        '0901000001',
        'an.nguyen@gmail.com'
    ),
    (
        '079100000002',
        'Trần Thị Bình',
        '1985-08-20',
        'Nữ',
        '456 Lê Lợi, Q1, TP.HCM',
        '0901000002',
        'binh.tran@gmail.com'
    ),
    (
        '079100000003',
        'Lê Hoàng Cường',
        '1988-12-10',
        'Nam',
        '789 Trần Hưng Đạo, Q5, TP.HCM',
        '0901000003',
        'cuong.le@gmail.com'
    ),
    (
        '079100000004',
        'Phạm Thị Dung',
        '1995-03-25',
        'Nữ',
        '321 Nguyễn Trãi, Q5, TP.HCM',
        '0901000004',
        'dung.pham@gmail.com'
    ),
    (
        '079100000005',
        'Hoàng Văn Em',
        '1992-07-08',
        'Nam',
        '654 Hùng Vương, Q5, TP.HCM',
        '0901000005',
        'em.hoang@gmail.com'
    ),
    (
        '079100000006',
        'Đỗ Thị Phương',
        '1998-11-30',
        'Nữ',
        '987 An Dương Vương, Q5, TP.HCM',
        '0901000006',
        'phuong.do@gmail.com'
    ),
    (
        '079100000007',
        'Vũ Minh Quang',
        '1987-04-12',
        'Nam',
        '147 Châu Văn Liêm, Q5, TP.HCM',
        '0901000007',
        'quang.vu@gmail.com'
    ),
    (
        '079100000008',
        'Bùi Thị Hương',
        '1993-09-18',
        'Nữ',
        '258 Trần Phú, Q5, TP.HCM',
        '0901000008',
        'huong.bui@gmail.com'
    ),
    (
        '079100000009',
        'Ngô Anh Tuấn',
        '1991-02-28',
        'Nam',
        '369 Hải Thượng Lãn Ông, Q5, TP.HCM',
        '0901000009',
        'tuan.ngo@gmail.com'
    ),
    (
        '079100000010',
        'Đinh Thị Kim',
        '1996-06-05',
        'Nữ',
        '741 Nguyễn Tri Phương, Q5, TP.HCM',
        '0901000010',
        'kim.dinh@gmail.com'
    ) ON CONFLICT (CCCD) DO NOTHING;
-- =============================================
-- LICHHEN: Lịch hẹn mẫu cho ngày hôm nay
-- Quầy Q1 (A) - Dân số Hộ tịch: 5 lịch hẹn
-- =============================================
-- Lịch hẹn cho Quầy A (ID=1, Prefix='A')
INSERT INTO LichHen (
        MaLichHen,
        CCCD,
        ThuTucId,
        QuayId,
        NgayHen,
        SoThuTu,
        PrefixSo,
        ThoiGianDuKien,
        TrangThai,
        NgayTao
    )
SELECT 'LH' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '001',
    '079100000001',
    lt.Id,
    q.Id,
    CURRENT_DATE,
    1,
    'A',
    '08:00:00',
    0,
    -- CHO_GOI
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q1'
    AND lt.MaThuTuc = 'KS' ON CONFLICT (NgayHen, QuayId, SoThuTu) DO NOTHING;
INSERT INTO LichHen (
        MaLichHen,
        CCCD,
        ThuTucId,
        QuayId,
        NgayHen,
        SoThuTu,
        PrefixSo,
        ThoiGianDuKien,
        TrangThai,
        NgayTao
    )
SELECT 'LH' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '002',
    '079100000002',
    lt.Id,
    q.Id,
    CURRENT_DATE,
    2,
    'A',
    '08:20:00',
    0,
    -- CHO_GOI
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q1'
    AND lt.MaThuTuc = 'HK' ON CONFLICT (NgayHen, QuayId, SoThuTu) DO NOTHING;
INSERT INTO LichHen (
        MaLichHen,
        CCCD,
        ThuTucId,
        QuayId,
        NgayHen,
        SoThuTu,
        PrefixSo,
        ThoiGianDuKien,
        TrangThai,
        NgayTao
    )
SELECT 'LH' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '003',
    '079100000003',
    lt.Id,
    q.Id,
    CURRENT_DATE,
    3,
    'A',
    '08:35:00',
    0,
    -- CHO_GOI
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q1'
    AND lt.MaThuTuc = 'CCCD' ON CONFLICT (NgayHen, QuayId, SoThuTu) DO NOTHING;
INSERT INTO LichHen (
        MaLichHen,
        CCCD,
        ThuTucId,
        QuayId,
        NgayHen,
        SoThuTu,
        PrefixSo,
        ThoiGianDuKien,
        TrangThai,
        NgayTao
    )
SELECT 'LH' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '004',
    '079100000004',
    lt.Id,
    q.Id,
    CURRENT_DATE,
    4,
    'A',
    '09:00:00',
    0,
    -- CHO_GOI
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q1'
    AND lt.MaThuTuc = 'KS' ON CONFLICT (NgayHen, QuayId, SoThuTu) DO NOTHING;
INSERT INTO LichHen (
        MaLichHen,
        CCCD,
        ThuTucId,
        QuayId,
        NgayHen,
        SoThuTu,
        PrefixSo,
        ThoiGianDuKien,
        TrangThai,
        NgayTao
    )
SELECT 'LH' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '005',
    '079100000005',
    lt.Id,
    q.Id,
    CURRENT_DATE,
    5,
    'A',
    '09:20:00',
    0,
    -- CHO_GOI
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q1'
    AND lt.MaThuTuc = 'HK' ON CONFLICT (NgayHen, QuayId, SoThuTu) DO NOTHING;
-- =============================================
-- LICHHEN: Quầy B (ID=2, Prefix='B') - 3 lịch hẹn
-- =============================================
INSERT INTO LichHen (
        MaLichHen,
        CCCD,
        ThuTucId,
        QuayId,
        NgayHen,
        SoThuTu,
        PrefixSo,
        ThoiGianDuKien,
        TrangThai,
        NgayTao
    )
SELECT 'LH' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '006',
    '079100000006',
    lt.Id,
    q.Id,
    CURRENT_DATE,
    1,
    'B',
    '08:00:00',
    0,
    -- CHO_GOI
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q2'
    AND lt.MaThuTuc = 'CCCD' ON CONFLICT (NgayHen, QuayId, SoThuTu) DO NOTHING;
INSERT INTO LichHen (
        MaLichHen,
        CCCD,
        ThuTucId,
        QuayId,
        NgayHen,
        SoThuTu,
        PrefixSo,
        ThoiGianDuKien,
        TrangThai,
        NgayTao
    )
SELECT 'LH' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '007',
    '079100000007',
    lt.Id,
    q.Id,
    CURRENT_DATE,
    2,
    'B',
    '08:25:00',
    0,
    -- CHO_GOI
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q2'
    AND lt.MaThuTuc = 'KS' ON CONFLICT (NgayHen, QuayId, SoThuTu) DO NOTHING;
INSERT INTO LichHen (
        MaLichHen,
        CCCD,
        ThuTucId,
        QuayId,
        NgayHen,
        SoThuTu,
        PrefixSo,
        ThoiGianDuKien,
        TrangThai,
        NgayTao
    )
SELECT 'LH' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '008',
    '079100000008',
    lt.Id,
    q.Id,
    CURRENT_DATE,
    3,
    'B',
    '08:45:00',
    0,
    -- CHO_GOI
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q2'
    AND lt.MaThuTuc = 'HK' ON CONFLICT (NgayHen, QuayId, SoThuTu) DO NOTHING;
-- =============================================
-- LICHHEN: Quầy C (ID=3, Prefix='C') - Kinh doanh: 2 lịch hẹn
-- =============================================
INSERT INTO LichHen (
        MaLichHen,
        CCCD,
        ThuTucId,
        QuayId,
        NgayHen,
        SoThuTu,
        PrefixSo,
        ThoiGianDuKien,
        TrangThai,
        NgayTao
    )
SELECT 'LH' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '009',
    '079100000009',
    lt.Id,
    q.Id,
    CURRENT_DATE,
    1,
    'C',
    '08:00:00',
    0,
    -- CHO_GOI
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q3'
    AND lt.MaThuTuc = 'GPKD' ON CONFLICT (NgayHen, QuayId, SoThuTu) DO NOTHING;
INSERT INTO LichHen (
        MaLichHen,
        CCCD,
        ThuTucId,
        QuayId,
        NgayHen,
        SoThuTu,
        PrefixSo,
        ThoiGianDuKien,
        TrangThai,
        NgayTao
    )
SELECT 'LH' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '010',
    '079100000010',
    lt.Id,
    q.Id,
    CURRENT_DATE,
    2,
    'C',
    '08:30:00',
    0,
    -- CHO_GOI
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q3'
    AND lt.MaThuTuc = 'DKDN' ON CONFLICT (NgayHen, QuayId, SoThuTu) DO NOTHING;
-- =============================================
-- SUMMARY: Tổng hợp dữ liệu đã tạo
-- =============================================
-- Citizens: 10 công dân mẫu
-- LichHen: 
--   - Quầy A (Q1): 5 lịch hẹn (số A001-A005)
--   - Quầy B (Q2): 3 lịch hẹn (số B001-B003)  
--   - Quầy C (Q3): 2 lịch hẹn (số C001-C002)
--   - Quầy D (Q4): 0 lịch hẹn
-- 
-- Để test:
-- - Đăng nhập với NV001 (Quầy A) → thấy 5 người chờ
-- - Đăng nhập với NV002 (Quầy B) → thấy 3 người chờ
-- - Đăng nhập với NV003 (Quầy C) → thấy 2 người chờ
-- - Đăng nhập với NV004 (Quầy D) → hàng chờ trống