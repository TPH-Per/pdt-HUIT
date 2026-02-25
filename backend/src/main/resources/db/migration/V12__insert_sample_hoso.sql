-- =============================================
-- HỆ THỐNG QUẢN LÝ QUẦY - CHỢ LỚN HCMC
-- PostgreSQL Database Migration V12
-- Insert Sample HoSo Data (For Testing Document Management)
-- =============================================
-- =============================================
-- HOSO: Hồ sơ mẫu để test
-- Sử dụng Citizens đã có từ V11
-- =============================================
-- Hồ sơ 1: Quầy A, Trạng thái MỚI
INSERT INTO HoSo (
        MaHoSo,
        CCCD,
        LoaiThuTucId,
        QuayId,
        TrangThai,
        DoUuTien,
        HanXuLy,
        NgayNop
    )
SELECT 'HS' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '0001',
    '079100000001',
    lt.Id,
    q.Id,
    1,
    -- MỚI
    0,
    -- Bình thường
    CURRENT_DATE + lt.ThoiGianXuLy,
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q1'
    AND lt.MaThuTuc = 'KS' ON CONFLICT (MaHoSo) DO NOTHING;
-- Hồ sơ 2: Quầy A, Trạng thái ĐANG XỬ LÝ
INSERT INTO HoSo (
        MaHoSo,
        CCCD,
        LoaiThuTucId,
        QuayId,
        TrangThai,
        DoUuTien,
        HanXuLy,
        NgayNop
    )
SELECT 'HS' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '0002',
    '079100000002',
    lt.Id,
    q.Id,
    1,
    -- ĐANG XỬ LÝ
    1,
    -- Ưu tiên
    CURRENT_DATE + lt.ThoiGianXuLy,
    CURRENT_TIMESTAMP - INTERVAL '2 hours'
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q1'
    AND lt.MaThuTuc = 'HK' ON CONFLICT (MaHoSo) DO NOTHING;
-- Hồ sơ 3: Quầy A, Trạng thái CẦN BỔ SUNG
INSERT INTO HoSo (
        MaHoSo,
        CCCD,
        LoaiThuTucId,
        QuayId,
        TrangThai,
        DoUuTien,
        HanXuLy,
        NgayNop,
        GhiChu
    )
SELECT 'HS' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '0003',
    '079100000003',
    lt.Id,
    q.Id,
    2,
    -- CẦN BỔ SUNG
    0,
    CURRENT_DATE + lt.ThoiGianXuLy,
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    'Yêu cầu bổ sung sổ hộ khẩu bản sao'
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q1'
    AND lt.MaThuTuc = 'CCCD' ON CONFLICT (MaHoSo) DO NOTHING;
-- Hồ sơ 4: Quầy A, Trạng thái CHỜ PHÊ DUYỆT
INSERT INTO HoSo (
        MaHoSo,
        CCCD,
        LoaiThuTucId,
        QuayId,
        TrangThai,
        DoUuTien,
        HanXuLy,
        NgayNop
    )
SELECT 'HS' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '0004',
    '079100000004',
    lt.Id,
    q.Id,
    1,
    -- CHỜ PHÊ DUYỆT
    2,
    -- Khẩn cấp
    CURRENT_DATE + lt.ThoiGianXuLy,
    CURRENT_TIMESTAMP - INTERVAL '3 hours'
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q1'
    AND lt.MaThuTuc = 'KS' ON CONFLICT (MaHoSo) DO NOTHING;
-- Hồ sơ 5: Quầy A, Trạng thái HOÀN THÀNH
INSERT INTO HoSo (
        MaHoSo,
        CCCD,
        LoaiThuTucId,
        QuayId,
        TrangThai,
        DoUuTien,
        HanXuLy,
        NgayNop,
        NgayHoanThanh
    )
SELECT 'HS' || TO_CHAR(CURRENT_DATE - 1, 'YYYYMMDD') || '0001',
    '079100000005',
    lt.Id,
    q.Id,
    4,
    -- HOÀN THÀNH
    0,
    CURRENT_DATE - 1 + lt.ThoiGianXuLy,
    CURRENT_TIMESTAMP - INTERVAL '1 day',
    CURRENT_TIMESTAMP - INTERVAL '2 hours'
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q1'
    AND lt.MaThuTuc = 'HK' ON CONFLICT (MaHoSo) DO NOTHING;
-- =============================================
-- Hồ sơ cho Quầy B
-- =============================================
-- Hồ sơ 6: Quầy B, Trạng thái MỚI
INSERT INTO HoSo (
        MaHoSo,
        CCCD,
        LoaiThuTucId,
        QuayId,
        TrangThai,
        DoUuTien,
        HanXuLy,
        NgayNop
    )
SELECT 'HS' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '0005',
    '079100000006',
    lt.Id,
    q.Id,
    1,
    -- MỚI
    0,
    CURRENT_DATE + lt.ThoiGianXuLy,
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q2'
    AND lt.MaThuTuc = 'KS' ON CONFLICT (MaHoSo) DO NOTHING;
-- Hồ sơ 7: Quầy B, Trạng thái ĐANG XỬ LÝ
INSERT INTO HoSo (
        MaHoSo,
        CCCD,
        LoaiThuTucId,
        QuayId,
        TrangThai,
        DoUuTien,
        HanXuLy,
        NgayNop
    )
SELECT 'HS' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '0006',
    '079100000007',
    lt.Id,
    q.Id,
    1,
    -- ĐANG XỬ LÝ
    0,
    CURRENT_DATE + lt.ThoiGianXuLy,
    CURRENT_TIMESTAMP - INTERVAL '1 hour'
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q2'
    AND lt.MaThuTuc = 'CCCD' ON CONFLICT (MaHoSo) DO NOTHING;
-- =============================================
-- Hồ sơ cho Quầy C (Kinh doanh)
-- =============================================
-- Hồ sơ 8: Quầy C, Trạng thái MỚI
INSERT INTO HoSo (
        MaHoSo,
        CCCD,
        LoaiThuTucId,
        QuayId,
        TrangThai,
        DoUuTien,
        HanXuLy,
        NgayNop
    )
SELECT 'HS' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '0007',
    '079100000008',
    lt.Id,
    q.Id,
    1,
    -- MỚI
    1,
    -- Ưu tiên
    CURRENT_DATE + lt.ThoiGianXuLy,
    CURRENT_TIMESTAMP
FROM Quay q,
    LoaiThuTuc lt
WHERE q.MaQuay = 'Q3'
    AND lt.MaThuTuc = 'GPKD' ON CONFLICT (MaHoSo) DO NOTHING;
-- =============================================
-- HOSOXULY: Lịch sử xử lý mẫu
-- =============================================
-- Log cho hồ sơ 2 (đang xử lý)
INSERT INTO HoSoXuLy (
        HoSoId,
        UserId,
        HanhDong,
        TrangThaiCu,
        TrangThaiMoi,
        NoiDung,
        ThoiGianBatDau
    )
SELECT h.Id,
    u.Id,
    'TAO_MOI',
    NULL,
    1,
    'Tạo mới hồ sơ',
    CURRENT_TIMESTAMP - INTERVAL '2 hours'
FROM HoSo h,
    Users u
WHERE h.MaHoSo LIKE '%0002'
    AND u.MaNhanVien = 'NV001' ON CONFLICT DO NOTHING;
INSERT INTO HoSoXuLy (
        HoSoId,
        UserId,
        HanhDong,
        TrangThaiCu,
        TrangThaiMoi,
        NoiDung,
        ThoiGianBatDau
    )
SELECT h.Id,
    u.Id,
    'CHUYEN_TRANG_THAI',
    1,
    1,
    'Bắt đầu xử lý hồ sơ',
    CURRENT_TIMESTAMP - INTERVAL '1 hour'
FROM HoSo h,
    Users u
WHERE h.MaHoSo LIKE '%0002'
    AND u.MaNhanVien = 'NV001' ON CONFLICT DO NOTHING;
-- =============================================
-- SUMMARY: Tổng hợp dữ liệu đã tạo
-- =============================================
-- HoSo: 8 hồ sơ mẫu
--   - Quầy A (Q1): 5 hồ sơ (các trạng thái khác nhau)
--   - Quầy B (Q2): 2 hồ sơ
--   - Quầy C (Q3): 1 hồ sơ
-- 
-- Để test:
-- - Đăng nhập NV001 (Quầy A) → thấy 5 hồ sơ
-- - Đăng nhập NV002 (Quầy B) → thấy 2 hồ sơ
-- - Dùng filter trangThai=0 để lọc hồ sơ mới