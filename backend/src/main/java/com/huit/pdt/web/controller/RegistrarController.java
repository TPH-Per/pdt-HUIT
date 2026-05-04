package com.huit.pdt.web.controller;

import com.huit.pdt.web.dto.CreateRegistrarRequest;
import com.huit.pdt.web.dto.UpdateProfileRequest;
import com.huit.pdt.web.dto.RegistrarResponse;
import com.huit.pdt.domain.auth.service.RegistrarService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller quản lý Cán bộ đào tạo — Hệ thống quản lý Phòng Đào tạo
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class RegistrarController {

    private final RegistrarService registrarService;

    // ==================== ADMIN ENDPOINTS ====================

    @PostMapping("/admin/registrar")
    @PreAuthorize("hasRole('Admin')")
    public ResponseEntity<RegistrarResponse> createRegistrar(@Valid @RequestBody CreateRegistrarRequest request) {
        log.info("Admin creating registrar: {}", request.getRegistrarCode());
        RegistrarResponse response = registrarService.createRegistrar(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/admin/registrar")
    @PreAuthorize("hasRole('Admin')")
    public ResponseEntity<List<RegistrarResponse>> getAllRegistrars() {
        List<RegistrarResponse> registrars = registrarService.getAllRegistrars();
        return ResponseEntity.ok(registrars);
    }

    @GetMapping("/admin/registrar/{id}")
    @PreAuthorize("hasRole('Admin')")
    public ResponseEntity<RegistrarResponse> getRegistrarById(@PathVariable Integer id) {
        RegistrarResponse registrar = registrarService.getRegistrarById(id);
        return ResponseEntity.ok(registrar);
    }

    @PostMapping("/admin/registrar/{id}/reset-password")
    @PreAuthorize("hasRole('Admin')")
    public ResponseEntity<Map<String, String>> adminResetPassword(
            @PathVariable Integer id,
            @RequestBody Map<String, String> request) {
        String newPassword = request.get("newPassword");
        if (newPassword == null || newPassword.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "newPassword is required"));
        }
        registrarService.resetPassword(id, newPassword);
        return ResponseEntity.ok(Map.of("message", "Đã đặt lại mật khẩu"));
    }

    @PostMapping("/admin/registrar/{id}/toggle-active")
    @PreAuthorize("hasRole('Admin')")
    public ResponseEntity<RegistrarResponse> toggleActive(@PathVariable Integer id) {
        RegistrarResponse registrar = registrarService.toggleActive(id);
        return ResponseEntity.ok(registrar);
    }

    @DeleteMapping("/admin/registrar/{id}")
    @PreAuthorize("hasRole('Admin')")
    public ResponseEntity<Map<String, String>> deleteRegistrar(@PathVariable Integer id) {
        registrarService.deleteRegistrar(id);
        return ResponseEntity.ok(Map.of("message", "Đã khóa tài khoản cán bộ"));
    }

    // ==================== REGISTRAR SELF-SERVICE ENDPOINTS ====================

    @GetMapping("/registrar/profile")
    public ResponseEntity<RegistrarResponse> getProfile() {
        var auth = org.springframework.security.core.context.SecurityContextHolder
                .getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof com.huit.pdt.infrastructure.security.CustomUserDetails) {
            Integer id = ((com.huit.pdt.infrastructure.security.CustomUserDetails) auth.getPrincipal()).getId();
            RegistrarResponse registrar = registrarService.getRegistrarById(id);
            return ResponseEntity.ok(registrar);
        }
        throw new RuntimeException("Không tìm thấy cán bộ đang đăng nhập");
    }

    @PutMapping("/registrar/profile")
    public ResponseEntity<RegistrarResponse> updateProfile(@Valid @RequestBody UpdateProfileRequest request) {
        RegistrarResponse registrar = registrarService.updateProfile(request);
        return ResponseEntity.ok(registrar);
    }

    @PostMapping("/registrar/change-password")
    public ResponseEntity<Map<String, String>> changePassword(@RequestBody Map<String, String> request) {
        String oldPassword = request.get("oldPassword");
        String newPassword = request.get("newPassword");

        if (oldPassword == null || newPassword == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "oldPassword and newPassword are required"));
        }
        if (newPassword.length() < 6) {
            return ResponseEntity.badRequest().body(Map.of("error", "Mật khẩu mới ít nhất 6 ký tự"));
        }

        registrarService.changePassword(oldPassword, newPassword);
        return ResponseEntity.ok(Map.of("message", "Đã đổi mật khẩu thành công"));
    }

    @GetMapping("/registrar/list")
    public ResponseEntity<List<RegistrarResponse>> getActiveRegistrars() {
        List<RegistrarResponse> registrars = registrarService.getAllActiveRegistrars();
        return ResponseEntity.ok(registrars);
    }
}












