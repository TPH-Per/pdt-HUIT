package com.example.demo.controller;

import com.example.demo.dto.request.CreateUserRequest;
import com.example.demo.dto.request.UpdateUserRequest;
import com.example.demo.dto.response.ApiResponse;
import com.example.demo.dto.response.UserResponse;
import com.example.demo.entity.ServiceDesk;
import com.example.demo.entity.Role;
import com.example.demo.entity.Registrar;
import com.example.demo.repository.ServiceDeskRepository;
import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.RegistrarRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Controller quản lý tài khoản cán bộ đào tạo (Admin)
 */
@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('Admin')")
@Transactional
public class UserController {

    private final RegistrarRepository registrarRepository;
    private final RoleRepository roleRepository;
    private final ServiceDeskRepository serviceDeskRepository;
    private final PasswordEncoder passwordEncoder;

    @GetMapping
    public ResponseEntity<ApiResponse<List<UserResponse>>> getAllUsers() {
        log.info("Getting all users");
        List<UserResponse> users = registrarRepository.findAll().stream()
                .map(this::mapToUserResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(users));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> getUserById(@PathVariable Integer id) {
        Registrar registrar = registrarRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ với ID: " + id));
        return ResponseEntity.ok(ApiResponse.success(mapToUserResponse(registrar)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserResponse>> createUser(@Valid @RequestBody CreateUserRequest request) {
        log.info("Creating user: {}", request.getMaNhanVien());

        if (registrarRepository.existsByRegistrarCode(request.getMaNhanVien())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("DUPLICATE_CODE", "Mã cán bộ đã tồn tại: " + request.getMaNhanVien()));
        }

        if (request.getEmail() != null && registrarRepository.existsByEmail(request.getEmail())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("DUPLICATE_EMAIL", "Email đã tồn tại: " + request.getEmail()));
        }

        Role role = roleRepository.findById(request.getRoleId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy vai trò với ID: " + request.getRoleId()));

        ServiceDesk serviceDesk = null;
        if (request.getQuayId() != null) {
            serviceDesk = serviceDeskRepository.findById(request.getQuayId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy quầy với ID: " + request.getQuayId()));
        }

        Registrar registrar = Registrar.builder()
                .registrarCode(request.getMaNhanVien())
                .fullName(request.getHoTen())
                .email(request.getEmail())
                .phone(request.getSoDienThoai())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(role)
                .serviceDesk(serviceDesk)
                .isActive(true)
                .build();

        registrar = registrarRepository.save(registrar);
        log.info("User created: {}", registrar.getRegistrarCode());

        return ResponseEntity.ok(ApiResponse.success(mapToUserResponse(registrar), "Tạo tài khoản thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> updateUser(
            @PathVariable Integer id,
            @RequestBody UpdateUserRequest request) {

        Registrar registrar = registrarRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ với ID: " + id));

        log.info("Updating user: {}", registrar.getRegistrarCode());

        if (request.getHoTen() != null)
            registrar.setFullName(request.getHoTen());
        if (request.getEmail() != null) {
            if (!request.getEmail().equals(registrar.getEmail())
                    && registrarRepository.existsByEmail(request.getEmail())) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("DUPLICATE_EMAIL", "Email đã tồn tại"));
            }
            registrar.setEmail(request.getEmail());
        }
        if (request.getSoDienThoai() != null)
            registrar.setPhone(request.getSoDienThoai());
        if (request.getRoleId() != null) {
            Role role = roleRepository.findById(request.getRoleId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy vai trò"));
            registrar.setRole(role);
        }
        if (request.getQuayId() != null) {
            ServiceDesk serviceDesk = serviceDeskRepository.findById(request.getQuayId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy quầy"));
            registrar.setServiceDesk(serviceDesk);
        }
        if (request.getTrangThai() != null)
            registrar.setIsActive(request.getTrangThai());
        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            registrar.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        }

        registrar = registrarRepository.save(registrar);
        log.info("User updated: {}", registrar.getRegistrarCode());

        return ResponseEntity.ok(ApiResponse.success(mapToUserResponse(registrar), "Cập nhật thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable Integer id) {
        Registrar registrar = registrarRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ với ID: " + id));

        log.info("Deleting (deactivating) user: {}", registrar.getRegistrarCode());
        registrar.setIsActive(false);
        registrarRepository.save(registrar);

        return ResponseEntity.ok(ApiResponse.success(null, "Đã khóa tài khoản"));
    }

    @PostMapping("/{id}/reset-password")
    public ResponseEntity<ApiResponse<UserResponse>> resetPassword(
            @PathVariable Integer id,
            @RequestBody Map<String, String> request) {

        String newPassword = request.get("newPassword");
        if (newPassword == null || newPassword.length() < 6) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_PASSWORD", "Mật khẩu phải có ít nhất 6 ký tự"));
        }

        Registrar registrar = registrarRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ với ID: " + id));

        log.info("Resetting password for: {}", registrar.getRegistrarCode());
        registrar.setPasswordHash(passwordEncoder.encode(newPassword));
        registrarRepository.save(registrar);

        return ResponseEntity.ok(ApiResponse.success(mapToUserResponse(registrar), "Đã đặt lại mật khẩu"));
    }

    private UserResponse mapToUserResponse(Registrar registrar) {
        return UserResponse.builder()
                .id(registrar.getId())
                .maNhanVien(registrar.getRegistrarCode())
                .hoTen(registrar.getFullName())
                .email(registrar.getEmail())
                .soDienThoai(registrar.getPhone())
                .roleId(registrar.getRole() != null ? registrar.getRole().getId() : null)
                .roleName(registrar.getRole() != null ? registrar.getRole().getRoleName() : null)
                .roleDisplayName(registrar.getRole() != null ? registrar.getRole().getDisplayName() : null)
                .quayId(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getId() : null)
                .tenQuay(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getDeskName() : null)
                .trangThai(registrar.getIsActive())
                .ngayTao(registrar.getCreatedAt())
                .build();
    }
}
