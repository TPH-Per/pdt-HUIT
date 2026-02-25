# Hệ thống Quản lý Dịch vụ Sinh viên HUIT (pdt-HUIT)

Dự án này là hệ thống phục vụ công tác hành chính và học vụ của sinh viên Trường Đại học Công Thương TP.HCM (HUIT). Hệ thống bao gồm 3 phân hệ chính:
1. **Backend (Spring Boot)**: Cung cấp API lõi, quản lý cơ sở dữ liệu PostgreSQL.
2. **Admin/Staff Portal (Vue.js 3 + TypeScript)**: Giao diện web dành cho Nhân viên Phòng Đào Tạo thao tác, quản lý hồ sơ, lịch hẹn và các phản ánh từ sinh viên.
3. **Student Mobile App (Flutter)**: Ứng dụng di động dành cho sinh viên HUIT thực hiện đặt lịch hẹn, xem và nộp hồ sơ, kiểm tra thông báo và gửi góp ý.

## Cấu trúc dự án
- `backend/`: Chứa mã nguồn Spring Boot.
- `adminstaff/`: Chứa mã nguồn Vue.js cho cổng thông tin Cán bộ.
- `flutter_huit_student/`: Chứa mã nguồn ứng dụng di động Flutter dành cho sinh viên.
- `scripts/`: Chứa các kịch bản tiện ích như backup cơ sở dữ liệu.
- `docker-compose.prod.yml`: File cấu hình chạy môi trường production (PostgreSQL, Redis...).

## Hướng dẫn cài đặt và thiết lập Backend && Web Admin

### 1. Setup Backend (Spring Boot)
1. Hãy chắc chắn máy tính có cài sẵn **Java 21**, **Maven**, và **PostgreSQL** (hoặc chạy qua Docker).
2. Tạo trước cơ sở dữ liệu PostgreSQL cho dự án, mặc định là DB có tên `pdt`.
3. Thay đổi cấu hình kết nối DB bên trong `backend/src/main/resources/application.properties` nếu cần thiết (username, password).
4. Khởi chạy Backend:
   ```bash
   cd backend
   ./mvnw spring-boot:run
   ```
   *Lưu ý: Flyway sẽ tự động chạy các script `V*.sql` để tạo bangr và seed dữ liệu ban đầu.*

### 2. Setup Web Admin (Vue.js)
1. Cần có sẵn **Node.js** bản mới nhất.
2. Cài đặt các thư viện phụ thuộc:
   ```bash
   cd adminstaff
   npm install
   ```
3. Khởi chạy ở chế độ dev:
   ```bash
   npm run dev
   ```

---

## Hướng dẫn kết nối Mobile App (Flutter) với Backend

Điểm cốt yếu khi chạy **App Flutter** là thiết bị ngoại tuyến (điện thoại hoặc máy ảo) phải kết nối được với biến `127.0.0.1:8081` (Backend) đang rớt nằm trong localhost của máy vi tính. Các cấu hình kết nối như sau:

Cấu hình Base URL của App Flutter đang được đặt cứng tại file: 
`flutter_huit_student/lib/data/api_service.dart`

```dart
static const String _baseUrl = 'http://127.0.0.1:8081/api/student';
```

### Cách 1. Kết nối qua Điện Thoại Thật (Cable/Wi-Fi Debugging qua SCRCPY / ADB)
Nếu bạn cắm dây máy tính vào điện thoại vật lý (thông qua ADB, ví dụ như dùng ScrCpy):
* Môi trường localhost của điện thoại sẽ KHÔNG tự nhìn thấy localhost của Máy tính.
* Bạn bắt buộc phải **Reserve Port (Đảo ngược cổng kết nối)** thông qua ADB Terminal để map cổng 8081 của điện thoại về đúng 8081 của máy tính:

**Chạy lệnh sau trên terminal của Máy Tính:**
```bash
adb reverse tcp:8081 tcp:8081
```
*(Nếu app chạy thấy báo lỗi `Connection refused`, bạn phải gõ lại lệnh trên)*

Sau khi chạy xong lệnh Map Port, bạn chỉ cần Run app Flutter (đảm bảo Base URL giữ nguyên `127.0.0.1`):
```bash
cd flutter_huit_student
flutter run
```

### Cách 2. Kết nối qua Máy Ảo Android (Android Studio Emulator)
Tương tự như Điện thoại thật, Máy ảo Android có hệ thống LocalHost nằm tách biệt hoàn toàn so với máy tính đang chạy nó. Địa chỉ IP `127.0.0.1` trên máy ảo trỏ về chính bên trong máy ảo đó.
* Để máy ảo Android nhìn thấy localhost của máy tính Win/Mac/Linux, bạn phải đổi địa chỉ IP cấu hình Spring boot từ `127.0.0.1` thành **`10.0.2.2`** – Đây là địa chỉ alias mặc định đặc quyền của Emulator.

**Bạn phải vào sửa file `api_service.dart` trong mã nguồn Flutter:**
Hủy dòng cũ và cập nhật lại:
```dart
// static const String _baseUrl = 'http://127.0.0.1:8081/api/student'; // <-- Điện thoại thật / iOS Emulator
static const String _baseUrl = 'http://10.0.2.2:8081/api/student';     // <-- Android Emulator
```
*Lưu ý: Nếu xài iOS Simulator trên Mac thì vẫn dùng `127.0.0.1` bình thường, chỉ có máy ảo Android mới dùng `10.0.2.2`.*

Sau khi sửa, bạn khởi động lại app trên máy ảo.
