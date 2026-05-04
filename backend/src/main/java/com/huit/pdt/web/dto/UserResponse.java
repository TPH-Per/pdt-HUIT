package com.huit.pdt.web.dto;

import lombok.*;

import java.time.LocalDateTime;

/**
 * User/Staff Response DTO với field tiếng Việt
 * Để tương thích với frontend
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {

    private Integer id;
    private String maNhanVien;
    private String hoTen;
    private String email;
    private String soDienThoai;
    private Integer roleId;
    private String roleName;
    private String roleDisplayName;
    private Integer quayId;
    private String tenQuay;
    private Boolean trangThai;
    private LocalDateTime lanDangNhapCuoi;
    private LocalDateTime ngayTao;
}










