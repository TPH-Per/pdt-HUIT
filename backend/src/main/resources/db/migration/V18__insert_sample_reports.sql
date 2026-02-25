-- 1. Góp ý - Mới
INSERT INTO report (
        citizen_id,
        application_id,
        report_type,
        title,
        content,
        status,
        created_at
    )
SELECT c.citizen_id,
    (
        SELECT id
        FROM application
        ORDER BY id DESC
        LIMIT 1
    ), -- Lấy hồ sơ mới nhất
    0, -- Feedback
    'Góp ý về máy lạnh tại khu vực chờ', 'Khu vực chờ buổi chiều khá nóng, đề nghị kiểm tra lại hệ thống máy lạnh.', 0, -- NEW
    NOW() - INTERVAL '1 day'
FROM citizen c
ORDER BY c.citizen_id
LIMIT 1;
-- 2. Khiếu nại - Đang xử lý
INSERT INTO report (
        citizen_id,
        application_id,
        report_type,
        title,
        content,
        status,
        created_at
    )
SELECT c.citizen_id,
    (
        SELECT id
        FROM application
        ORDER BY id DESC OFFSET 1
        LIMIT 1
    ), 1, -- Complaint
    'Thái độ nhân viên tiếp nhận', 'Nhân viên tiếp nhận hồ sơ sáng nay hướng dẫn chưa rõ ràng, làm tôi phải đi lại nhiều lần bổ sung giấy tờ.', 0, -- NEW
    NOW() - INTERVAL '3 days'
FROM citizen c
ORDER BY c.citizen_id DESC
LIMIT 1;
-- 3. Khen ngợi - Đã giải quyết
INSERT INTO report (
        citizen_id,
        application_id,
        report_type,
        title,
        content,
        status,
        created_at
    )
SELECT c.citizen_id,
    (
        SELECT id
        FROM application
        ORDER BY id ASC
        LIMIT 1
    ), 2, -- Praise
    'Quy trình rất nhanh gọn', 'Tôi rất hài lòng với quy trình làm thủ tục Sao y bản chính. Chỉ mất 15 phút là xong.', 2, -- RESOLVED
    NOW() - INTERVAL '7 days'
FROM citizen c
ORDER BY c.citizen_id
LIMIT 1;
-- Thêm câu trả lời cho report khen ngợi
INSERT INTO reply (report_id, staff_id, content, created_at)
SELECT r.id,
    (
        SELECT id
        FROM staff
        ORDER BY id
        LIMIT 1
    ), -- Lấy staff đầu tiên bất kỳ
    'Thay mặt Ủy ban, xin cảm ơn những lời khen ngợi của công dân. Chúng tôi sẽ cố gắng duy trì và nâng cao chất lượng phục vụ.', NOW()
FROM report r
WHERE r.title = 'Quy trình rất nhanh gọn';