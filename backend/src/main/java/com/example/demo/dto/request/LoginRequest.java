package com.example.demo.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request DTO for login
 * 
 * Endpoint: POST /api/auth/login
 * 
 * Example request body:
 * {
 * "username": "NV001",
 * "password": "123456"
 * }
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {

    @NotBlank(message = "Mã cán bộ không được để trống")
    @JsonAlias({ "staffCode", "maNhanVien", "registrarCode", "username" })
    private String username;

    @NotBlank(message = "Mật khẩu không được để trống")
    private String password;
}
