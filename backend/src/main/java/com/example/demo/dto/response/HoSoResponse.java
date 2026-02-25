package com.example.demo.dto.response;

import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HoSoResponse {
    private Integer id;
    private String maHoSo;
    private String mssv;
    private String hoTenSinhVien;
    private String soDienThoai;
    private String email;
    private String tenThuTuc; // Service name
    private String maThuTuc; // Service code
    private Integer trangThai;
    private String trangThaiText;
    private Integer doUuTien;
    private LocalDateTime ngayNop;
    private LocalDate hanXuLy;
    private String nguonGoc;
    private String maLichHen;
    private Integer loaiThuTucId; // Service ID
    private Integer thoiGianXuLyQuyDinh;
    private List<HistoryDto> lichSuXuLy;

    // Legacy Zalo fields (no longer used, kept for backward compat)
    private String zaloId;
    private String zaloName;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class HistoryDto {
        private String nguoiXuLy;
        private String hanhDong;
        private String trangThaiCu;
        private String trangThaiMoi;
        private String noiDung;
        private LocalDateTime thoiGian;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DashboardData {
        private Integer tongSoHoSo;
        private Integer choXuLy;
        private Integer dangXuLy;
        private Integer hoanThanh;
        private Integer treHan;
    }

    public static String getTrangThaiText(Integer phase) {
        if (phase == null)
            return "---";
        return switch (phase) {
            case 0 -> "Đã hủy";
            case 1 -> "Chờ gọi số";
            case 2 -> "Chờ xử lý";
            case 3 -> "Đang xử lý";
            case 4 -> "Hoàn thành";
            case 5 -> "Đã tiếp nhận";
            case 6 -> "Yêu cầu bổ sung";
            default -> "Không xác định";
        };
    }
}
