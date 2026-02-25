package com.example.demo.controller;

import com.example.demo.dto.request.LoginRequest;
import com.example.demo.dto.response.ApiResponse;
import com.example.demo.dto.response.LoginResponse;
import com.example.demo.dto.response.UserResponse;
import com.example.demo.entity.Registrar;
import com.example.demo.repository.RegistrarRepository;
import com.example.demo.service.AuthService;
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

    /**
     * Login endpoint
     * POST /api/auth/login
     */
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        log.info("Login request for registrar: {}", request.getUsername());
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Đăng nhập thành công"));
    }

    /**
     * Get current logged in registrar info
     * GET /api/auth/me
     */
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> getCurrentRegistrar() {
        UserResponse response = authService.getCurrentRegistrar();
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /**
     * Validate token
     * GET /api/auth/validate
     */
    @GetMapping("/validate")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> validateToken() {
        // If request reaches here, token is valid (JWT filter already validated)
        return ResponseEntity.ok(ApiResponse.success(Map.of("valid", true)));
    }

    /**
     * Health check endpoint
     * GET /api/auth/health
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "OK", "message", "Auth service is running"));
    }

    /**
     * Reset password (for development only!)
     * POST /api/auth/reset-password
     */
    @PostMapping("/reset-password")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<Map<String, String>> resetPassword(@RequestBody Map<String, String> request) {
        String registrarCode = request.get("registrarCode");
        if (registrarCode == null)
            registrarCode = request.get("staffCode");
        String newPassword = request.get("newPassword");

        if (registrarCode == null || newPassword == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "registrarCode and newPassword are required"));
        }

        Registrar registrar = registrarRepository.findByRegistrarCode(registrarCode)
                .orElse(null);

        if (registrar == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Registrar not found: " + registrarCode));
        }

        String hashedPassword = passwordEncoder.encode(newPassword);
        registrar.setPasswordHash(hashedPassword);
        registrarRepository.save(registrar);

        log.info("Password reset for registrar: {}", registrarCode);
        return ResponseEntity.ok(Map.of("message", "Password reset successfully for " + registrarCode));
    }

    /**
     * Update current user's profile
     * PUT /api/auth/profile
     */
    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserResponse>> updateProfile(
            @Valid @RequestBody com.example.demo.dto.request.UpdateProfileRequest request) {
        log.info("Update profile request");
        UserResponse response = authService.updateProfile(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Cập nhật thông tin thành công"));
    }

    /**
     * Change current user's password
     * POST /api/auth/change-password
     */
    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Map<String, String>>> changePassword(
            @Valid @RequestBody com.example.demo.dto.request.ChangePasswordRequest request) {
        log.info("Change password request");
        authService.changePassword(request);
        return ResponseEntity.ok(ApiResponse.success(
                Map.of("message", "Đổi mật khẩu thành công"),
                "Đổi mật khẩu thành công"));
    }
}
