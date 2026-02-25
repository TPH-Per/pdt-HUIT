-- =============================================
-- V16: Insert Sample Queue Data for Today
-- Thêm 10 lượt hẹn trong hàng chờ cho ngày hôm nay
-- =============================================
-- 1. Đảm bảo có đủ công dân trong hệ thống
INSERT INTO citizen (
        citizen_id,
        full_name,
        phone,
        email,
        date_of_birth,
        address
    )
VALUES (
        '012345678901',
        'Nguyễn Văn An',
        '0901000001',
        'an.nguyen@gmail.com',
        '1985-03-15',
        '123 Đường Nguyễn Trãi, Q5, TP.HCM'
    ),
    (
        '012345678902',
        'Trần Thị Bình',
        '0901000002',
        'binh.tran@gmail.com',
        '1990-07-22',
        '456 Đường Trần Hưng Đạo, Q5, TP.HCM'
    ),
    (
        '012345678903',
        'Lê Hoàng Cường',
        '0901000003',
        'cuong.le@gmail.com',
        '1988-11-10',
        '789 Đường Hùng Vương, Q5, TP.HCM'
    ),
    (
        '012345678904',
        'Phạm Thị Dung',
        '0901000004',
        'dung.pham@gmail.com',
        '1992-01-25',
        '321 Đường An Dương Vương, Q5, TP.HCM'
    ),
    (
        '012345678905',
        'Hoàng Văn Em',
        '0901000005',
        'em.hoang@gmail.com',
        '1995-05-08',
        '654 Đường Châu Văn Liêm, Q5, TP.HCM'
    ),
    (
        '012345678906',
        'Đỗ Thị Phương',
        '0901000006',
        'phuong.do@gmail.com',
        '1987-09-30',
        '987 Đường Phạm Hùng, Q5, TP.HCM'
    ),
    (
        '012345678907',
        'Vũ Minh Giang',
        '0901000007',
        'giang.vu@gmail.com',
        '1993-12-18',
        '147 Đường Lê Hồng Phong, Q5, TP.HCM'
    ),
    (
        '012345678908',
        'Bùi Thanh Hà',
        '0901000008',
        'ha.bui@gmail.com',
        '1989-04-05',
        '258 Đường Võ Văn Kiệt, Q5, TP.HCM'
    ),
    (
        '012345678909',
        'Ngô Văn Inh',
        '0901000009',
        'inh.ngo@gmail.com',
        '1991-08-12',
        '369 Đường Nguyễn Văn Cừ, Q5, TP.HCM'
    ),
    (
        '012345678910',
        'Đinh Thị Kim',
        '0901000010',
        'kim.dinh@gmail.com',
        '1994-02-28',
        '741 Đường Trần Bình Trọng, Q5, TP.HCM'
    ) ON CONFLICT (citizen_id) DO NOTHING;
-- 2. Tạo 10 Application (hồ sơ với lịch hẹn hôm nay) - trạng thái CHỜ GỌI (phase = 1)
DO $$
DECLARE v_procedure_id INTEGER;
v_counter_id INTEGER;
v_today DATE := CURRENT_DATE;
v_citizen_id VARCHAR(12);
v_app_code VARCHAR(50);
v_queue_num INTEGER;
v_expected_time TIME;
v_app_id INTEGER;
BEGIN -- Lấy procedure đầu tiên và counter đầu tiên
SELECT id INTO v_procedure_id
FROM procedure
WHERE is_active = true
LIMIT 1;
SELECT id INTO v_counter_id
FROM counter
WHERE is_active = true
LIMIT 1;
-- Nếu không có procedure hoặc counter, thoát
IF v_procedure_id IS NULL THEN RAISE NOTICE 'No active procedure found';
RETURN;
END IF;
IF v_counter_id IS NULL THEN RAISE NOTICE 'No active counter found';
RETURN;
END IF;
-- Tạo 10 lượt hẹn
FOR i IN 1..10 LOOP v_citizen_id := '0123456789' || LPAD(i::TEXT, 2, '0');
v_app_code := 'Q' || TO_CHAR(v_today, 'YYYYMMDD') || LPAD(i::TEXT, 3, '0');
v_queue_num := i;
v_expected_time := ('08:00'::TIME + (i * INTERVAL '15 minutes'))::TIME;
-- Kiểm tra xem application đã tồn tại chưa
IF NOT EXISTS (
    SELECT 1
    FROM application
    WHERE application_code = v_app_code
) THEN -- Insert application với phase = 1 (CHỜ GỌI)
INSERT INTO application (
        application_code,
        citizen_id,
        procedure_id,
        current_phase,
        queue_number,
        queue_prefix,
        priority,
        deadline,
        created_at
    )
VALUES (
        v_app_code,
        v_citizen_id,
        v_procedure_id,
        1,
        -- PHASE 1: CHỜ GỌI
        v_queue_num,
        'A',
        CASE
            WHEN i = 5 THEN 1
            ELSE 0
        END,
        -- Người thứ 5 ưu tiên
        v_today + INTERVAL '3 days',
        NOW()
    )
RETURNING id INTO v_app_id;
-- Insert vào application_history với thông tin appointment
INSERT INTO application_history (
        application_id,
        counter_id,
        phase_from,
        phase_to,
        action,
        content,
        appointment_date,
        expected_time,
        queue_number,
        queue_prefix,
        created_at
    )
VALUES (
        v_app_id,
        v_counter_id,
        0,
        1,
        'CREATE',
        'Đặt lịch hẹn qua Zalo',
        v_today,
        v_expected_time,
        v_queue_num,
        'A',
        NOW()
    );
RAISE NOTICE 'Created queue A% for citizen %',
v_queue_num,
v_citizen_id;
END IF;
END LOOP;
END $$;