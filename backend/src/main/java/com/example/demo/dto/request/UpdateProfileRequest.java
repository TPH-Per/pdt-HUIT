package com.example.demo.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateProfileRequest {

    @Size(min = 2, max = 100, message = "Họ tên phải từ 2-100 ký tự")
    private String hoTen;

    @Email(message = "Email không hợp lệ")
    private String email;

    @Size(max = 15, message = "Số điện thoại tối đa 15 ký tự")
    private String soDienThoai;

    // Password change fields
    private String oldPassword;
    private String newPassword;

    // Alias methods for English field names used in service
    public String getFullName() {
        return hoTen;
    }

    public String getPhone() {
        return soDienThoai;
    }
}
