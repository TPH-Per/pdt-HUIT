package com.huit.pdt.web.controller;

import com.huit.pdt.web.dto.LoginRequest;
import com.huit.pdt.web.dto.ApiResponse;
import com.huit.pdt.web.dto.LoginResponse;
import com.huit.pdt.web.dto.UserResponse;
import com.huit.pdt.domain.auth.dto.RefreshTokenRequest;
import com.huit.pdt.domain.auth.dto.LogoutRequest;
import com.huit.pdt.infrastructure.persistence.Registrar;
import com.huit.pdt.infrastructure.persistence.RegistrarRepository;
import com.huit.pdt.domain.auth.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final AuthService authService;
    private final RegistrarRepository registrarRepository;
    private final PasswordEncoder passwordEncoder;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        log.info("Login request for registrar: {}", request.getUsername());
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Đăng nhập thành công"));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<LoginResponse>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        log.info("Refresh token request");
        LoginResponse response = authService.refreshToken(request.refreshToken());
        return ResponseEntity.ok(ApiResponse.success(response, "Refresh token thành công"));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Map<String, String>>> logout(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody(required = false) LogoutRequest request) {
        String accessToken = null;
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            accessToken = authHeader.substring(7);
        }
        String refreshToken = request != null ? request.refreshToken() : null;
        authService.logout(accessToken, refreshToken);
        return ResponseEntity.ok(ApiResponse.success(Map.of("message", "Đăng xuất thành công"), "Đăng xuất thành công"));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> getCurrentRegistrar() {
        UserResponse response = authService.getCurrentRegistrar();
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/validate")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> validateToken() {
        return ResponseEntity.ok(ApiResponse.success(Map.of("valid", true)));
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "OK", "message", "Auth service is running"));
    }

    @PostMapping("/reset-password")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<Map<String, String>> resetPassword(@RequestBody Map<String, String> request) {
        String registrarCode = request.get("registrarCode");
        if (registrarCode == null) registrarCode = request.get("staffCode");
        String newPassword = request.get("newPassword");

        if (registrarCode == null || newPassword == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "registrarCode and newPassword are required"));
        }

        Registrar registrar = registrarRepository.findByRegistrarCode(registrarCode).orElse(null);

        if (registrar == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Registrar not found: " + registrarCode));
        }

        String hashedPassword = passwordEncoder.encode(newPassword);
        registrar.setPasswordHash(hashedPassword);
        registrarRepository.save(registrar);

        log.info("Password reset for registrar: {}", registrarCode);
        return ResponseEntity.ok(Map.of("message", "Password reset successfully for " + registrarCode));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserResponse>> updateProfile(@Valid @RequestBody com.huit.pdt.web.dto.UpdateProfileRequest request) {
        log.info("Update profile request");
        UserResponse response = authService.updateProfile(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Cập nhật thông tin thành công"));
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Map<String, String>>> changePassword(@Valid @RequestBody com.huit.pdt.web.dto.ChangePasswordRequest request) {
        log.info("Change password request");
        authService.changePassword(request);
        return ResponseEntity.ok(ApiResponse.success(Map.of("message", "Đổi mật khẩu thành công"), "Đổi mật khẩu thành công"));
    }
}
