# Kế hoạch Triển khai: Chức năng Quản lý Hồ sơ cho Nhân viên (Staff)

Tài liệu này hướng dẫn chi tiết các bước thực hiện backend (Spring Boot) và frontend (Vue) cho chức năng quản lý hồ sơ tại quầy.

---

## 1. Tổng quan Nghiệp vụ

### 1.1. Luồng xử lý Hồ sơ
```
[Công dân đến quầy] → [Tạo hồ sơ mới] → [Xử lý] → [Bổ sung (nếu cần)] → [Phê duyệt] → [Hoàn thành]
       ↓
[Từ Lịch hẹn] ────────────────────────┘
```

### 1.2. Trạng thái Hồ sơ
| Mã | Tên | Mô tả |
|----|-----|-------|
| 1 | ĐANG XỬ LÝ | Nhân viên đang xử lý |
| 2 | CẦN BỔ SUNG | Thiếu giấy tờ, cần người dân bổ sung |
| 4 | HOÀN THÀNH | Đã hoàn thành, trả kết quả |
| 5 | TỪ CHỐI | Bị từ chối (có lý do) |

### 1.3. Chức năng cho Staff
1. **Xem danh sách hồ sơ** tại quầy của mình
2. **Tạo hồ sơ mới** (từ lịch hẹn hoặc walk-in)
3. **Cập nhật trạng thái** hồ sơ
4. **Yêu cầu bổ sung** giấy tờ
5. **Hoàn thành** hồ sơ
6. **Xem lịch sử xử lý** hồ sơ

---

## 2. Database Schema (Đã có sẵn)

### Bảng HoSo
| Column | Type | Mô tả |
|--------|------|-------|
| Id | SERIAL | Primary key |
| MaHoSo | VARCHAR(20) | Mã hồ sơ unique (VD: HS20260126001) |
| CCCD | VARCHAR(12) | FK → Citizens |
| LoaiThuTucId | INT | FK → LoaiThuTuc |
| QuayId | INT | FK → Quay (quầy xử lý) |
| ThongTinHoSo | JSONB | Thông tin form động |
| FileDinhKem | JSONB | Danh sách file đính kèm |
| TrangThai | INT | 0-5 (xem bảng trạng thái) |
| DoUuTien | INT | 0=Thường, 1=Ưu tiên, 2=Khẩn |
| LichHenId | INT | FK → LichHen (nếu từ lịch hẹn) |
| HanXuLy | DATE | Hạn xử lý |

### Bảng HoSoXuLy (Audit Trail)
| Column | Type | Mô tả |
|--------|------|-------|
| Id | SERIAL | Primary key |
| HoSoId | INT | FK → HoSo |
| UserId | INT | FK → Users (nhân viên xử lý) |
| HanhDong | VARCHAR(50) | VD: "TAO_MOI", "CAP_NHAT", "YEU_CAU_BO_SUNG" |
| TrangThaiCu | INT | Trạng thái trước |
| TrangThaiMoi | INT | Trạng thái sau |
| NoiDung | TEXT | Nội dung/Ghi chú |
| ThoiGianBatDau | TIMESTAMP | Thời điểm bắt đầu |

---

## 3. Backend Implementation

### 3.1. Bước 1: Tạo Repository (`HoSoRepository`)
```java
public interface HoSoRepository extends JpaRepository<HoSo, Integer> {
    // Danh sách hồ sơ tại quầy
    List<HoSo> findByQuayIdOrderByDoUuTienDescNgayNopDesc(Integer quayId);
    
    // Danh sách theo trạng thái
    List<HoSo> findByQuayIdAndTrangThaiOrderByNgayNopDesc(Integer quayId, Integer trangThai);
    
    // Hồ sơ từ lịch hẹn
    Optional<HoSo> findByLichHenId(Integer lichHenId);
    
    // Thống kê
    long countByQuayIdAndTrangThai(Integer quayId, Integer trangThai);
    
    // Tìm kiếm
    Optional<HoSo> findByMaHoSo(String maHoSo);
}
```

### 3.2. Bước 2: Tạo DTOs
```
dto/
├── request/
│   ├── CreateHoSoRequest.java    (Tạo hồ sơ mới)
│   ├── UpdateHoSoRequest.java    (Cập nhật thông tin)
│   └── ChangeStatusRequest.java  (Đổi trạng thái + lý do)
└── response/
    ├── HoSoResponse.java         (Thông tin hồ sơ)
    ├── HoSoDetailResponse.java   (Chi tiết + lịch sử xử lý)
    └── HoSoDashboardResponse.java (Thống kê tổng hợp)
```

### 3.3. Bước 3: Tạo Service (`HoSoService`)
**Methods cần implement:**

| Method | Mô tả |
|--------|-------|
| `getDanhSachHoSo(User staff, Integer trangThai)` | Lấy danh sách hồ sơ tại quầy |
| `getHoSoById(Integer id)` | Xem chi tiết hồ sơ |
| `createHoSo(CreateHoSoRequest request, User staff)` | Tạo hồ sơ mới |
| `createHoSoFromLichHen(Integer lichHenId, User staff)` | Tạo từ lịch hẹn |
| `updateTrangThai(Integer id, ChangeStatusRequest request, User staff)` | Đổi trạng thái |
| `getDashboard(User staff)` | Thống kê tổng hợp |

### 3.4. Bước 4: Tạo Controller (`StaffHoSoController`)
```
GET  /api/staff/hoso                    → Danh sách hồ sơ
GET  /api/staff/hoso/dashboard          → Dashboard thống kê
GET  /api/staff/hoso/{id}               → Chi tiết hồ sơ
POST /api/staff/hoso                    → Tạo hồ sơ mới
POST /api/staff/hoso/from-lichhen/{id}  → Tạo từ lịch hẹn
PUT  /api/staff/hoso/{id}/status        → Cập nhật trạng thái
PUT  /api/staff/hoso/{id}               → Cập nhật thông tin
```

---

## 4. Frontend Implementation

### 4.1. API Service
Thêm vào `api.ts`:
```typescript
export const hoSoApi = {
    getList: (trangThai?: number) => api.get('/staff/hoso', { params: { trangThai } }),
    getDashboard: () => api.get('/staff/hoso/dashboard'),
    getById: (id: number) => api.get(`/staff/hoso/${id}`),
    create: (data: CreateHoSoRequest) => api.post('/staff/hoso', data),
    createFromLichHen: (lichHenId: number) => api.post(`/staff/hoso/from-lichhen/${lichHenId}`),
    updateStatus: (id: number, data: ChangeStatusRequest) => api.put(`/staff/hoso/${id}/status`, data),
    update: (id: number, data: UpdateHoSoRequest) => api.put(`/staff/hoso/${id}`, data),
}
```

### 4.2. Components/Views
```
views/staff/
├── FileProcessing.vue      (Trang chính - danh sách hồ sơ)
├── HoSoDetail.vue          (Chi tiết hồ sơ - có thể dùng modal)
└── CreateHoSo.vue          (Form tạo hồ sơ mới)
```

### 4.3. UI Features
1. **Dashboard Cards**: Thống kê theo trạng thái
2. **Tabs/Filter**: Lọc theo trạng thái (Mới, Đang XL, Cần BS, Chờ PD)
3. **Table**: Danh sách hồ sơ với actions
4. **Detail Modal**: Xem chi tiết + timeline lịch sử
5. **Status Actions**: Buttons đổi trạng thái phù hợp

---

## 5. Thứ tự Thực hiện

### Phase 1: Backend Core
- [ ] 1.1. Tạo `HoSoRepository`
- [ ] 1.2. Tạo `HoSoXuLyRepository`
- [ ] 1.3. Tạo DTOs (Request + Response)
- [ ] 1.4. Tạo `HoSoService`
- [ ] 1.5. Tạo `StaffHoSoController`

### Phase 2: Backend Extended
- [ ] 2.1. Thêm validation logic
- [ ] 2.2. Tạo migration dữ liệu mẫu
- [ ] 2.3. Unit tests (optional)

### Phase 3: Frontend
- [ ] 3.1. Thêm API functions vào `api.ts`
- [ ] 3.2. Tạo `FileProcessing.vue`
- [ ] 3.3. Tạo `HoSoDetail.vue` (modal)
- [ ] 3.4. Tạo `CreateHoSo.vue` (modal/page)

### Phase 4: Integration
- [ ] 4.1. Kết nối Queue → HoSo (tạo hồ sơ sau khi hoàn thành)
- [ ] 4.2. Test end-to-end

---

## 6. Business Rules

1. **Tạo hồ sơ từ lịch hẹn**: Sau khi nhân viên hoàn thành lượt (queue), có thể tạo hồ sơ liên kết
2. **Chỉ quầy phụ trách**: Nhân viên chỉ thấy hồ sơ của quầy được gán
3. **Workflow trạng thái**:
   - MỚI → ĐANG XỬ LÝ ✅
   - ĐANG XỬ LÝ → CẦN BỔ SUNG / CHỜ PHÊ DUYỆT / TỪ CHỐI ✅
   - CẦN BỔ SUNG → ĐANG XỬ LÝ (khi người dân bổ sung) ✅
   - CHỜ PHÊ DUYỆT → HOÀN THÀNH / TỪ CHỐI (Admin/Leader) ✅
4. **Audit trail**: Mọi thay đổi trạng thái đều được ghi vào `HoSoXuLy`
5. **Hạn xử lý**: Tự động tính dựa trên `LoaiThuTuc.thoiGianXuLy`

---

## 7. Ước tính Thời gian

| Phase | Công việc | Thời gian |
|-------|-----------|-----------|
| Phase 1 | Backend Core | 2-3 giờ |
| Phase 2 | Backend Extended | 1-2 giờ |
| Phase 3 | Frontend | 3-4 giờ |
| Phase 4 | Integration & Test | 1-2 giờ |
| **Tổng** | | **7-11 giờ** |
