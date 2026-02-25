# HUIT Student – Phòng Đào Tạo

Ứng dụng Flutter dành cho sinh viên Trường Đại Học Công Thương TP.HCM (HUIT), phục vụ quản lý thủ tục tại **Phòng Đào Tạo**.

---

## Màu sắc thương hiệu (Brand Colors)

| Tên                      | HEX       | Mục đích                                     |
|--------------------------|-----------|----------------------------------------------|
| Xanh HUIT (Primary)      | `#003865` | Header, Sidebar, nút chính, icon chủ đạo     |
| Xanh sáng (Primary Light)| `#0B4271` | Gradient, hover                              |
| Đỏ HUIT (Accent)         | `#D31826` | Accent, cảnh báo, nút huỷ                   |
| Nền tổng thể             | `#F4F6F9` | App Background                               |
| Nền card                 | `#FFFFFF` | Form, bảng biểu, card nội dung               |
| Viền                     | `#E0E0E0` | Divider, input border                        |
| Chữ tiêu đề              | `#1A1A1A` | Heading Text                                 |
| Chữ nội dung             | `#333333` | Body Text                                    |
| Chữ phụ trợ              | `#6C757D` | Placeholder, ghi chú                         |
| Thành công               | `#28A745` | Hồ sơ duyệt, hoàn thành                     |
| Cảnh báo                 | `#FFC107` | Đang chờ xử lý                              |

---

## Cấu trúc dự án

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + Provider scope
├── core/
│   ├── app_state.dart           # Global state (auth, appointments, docs)
│   └── theme/
│       ├── app_colors.dart      # Bảng màu HUIT đầy đủ
│       ├── app_text_styles.dart # Typography (Google Fonts Inter)
│       └── app_theme.dart       # ThemeData Material 3
├── data/
│   ├── models.dart              # Specialty, Procedure, Appointment, Document…
│   ├── mock_data.dart           # Mock data (Phòng Đào Tạo HUIT)
│   └── api_service.dart         # HTTP client → Spring Boot backend
├── features/
│   ├── auth/login_page.dart     # Đăng nhập MSSV + mật khẩu
│   ├── home/home_page.dart      # Trang chủ với hero banner
│   ├── booking/                 # Đặt lịch hẹn (4 bước)
│   ├── appointments/            # Danh sách lịch hẹn (3 tab)
│   ├── queue/                   # Theo dõi hàng đợi realtime
│   ├── documents/               # Hồ sơ số
│   ├── profile/                 # Trang cá nhân
│   └── feedback/                # Góp ý (gửi + lịch sử)
└── shared/
    ├── layouts/main_layout.dart # Bottom navigation (5 tab)
    └── widgets/
        ├── huit_app_bar.dart    # App bar + hero header
        ├── huit_button.dart     # Button (5 variants, 3 sizes)
        └── status_badge.dart    # Badge trạng thái hồ sơ
```

---

## Tính năng

| Trang          | Tính năng                                                         |
|----------------|-------------------------------------------------------------------|
| **Đăng nhập**  | Nhập MSSV, mật khẩu, validate, animation                        |
| **Trang chủ**  | Hero banner, Quick Actions, thủ tục phổ biến, thông báo mới     |
| **Đặt lịch**   | 4 bước: Danh mục → Thủ tục → Chọn ngày/giờ → Xác nhận          |
| **Lịch hẹn**   | 3 tab: Sắp tới / Hoàn thành / Đã huỷ, Pull-to-refresh           |
| **Hàng đợi**   | Live tracking, số giờ chờ ước tính, tự refresh 30s              |
| **Hồ sơ số**   | Filter theo loại, upload sheet, menu tùy chọn                    |
| **Cá nhân**    | Chỉnh sửa thông tin, thông tin học vụ, đăng xuất                |
| **Góp ý**      | Form đánh giá sao + nội dung, xem lịch sử phản hồi              |

---

## Cài đặt & Chạy

```bash
# 1. Đảm bảo Flutter ≥ 3.16
flutter --version

# 2. Cài dependencies
flutter pub get

# 3. Chạy ứng dụng
flutter run

# 4. Build APK
flutter build apk --release
```

---

## Kết nối Backend

Ứng dụng kết nối đến Spring Boot backend tại `http://localhost:8081/api/citizen`.  
Trong trường hợp backend chưa chạy, ứng dụng tự động dùng **mock data offline**.

---

## Assets

- Logo: `assets/images/huit_logo.webp` (copy từ AdminStaff)
- Font: **Inter** (tải tự động qua `google_fonts`)
