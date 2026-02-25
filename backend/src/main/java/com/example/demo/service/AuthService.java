package com.example.demo.service;

import com.example.demo.dto.request.LoginRequest;
import com.example.demo.dto.request.ChangePasswordRequest;
import com.example.demo.dto.request.UpdateProfileRequest;
import com.example.demo.dto.response.LoginResponse;
import com.example.demo.dto.response.UserResponse;
import com.example.demo.entity.Registrar;
import com.example.demo.repository.RegistrarRepository;
import com.example.demo.security.CustomUserDetails;
import com.example.demo.security.JwtUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service xác thực — Hệ thống quản lý Phòng Đào tạo
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final JwtUtils jwtUtils;
    private final RegistrarRepository registrarRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        log.info("Login attempt: {}", request.getUsername());

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getUsername(),
                        request.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);

        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();

        // Reload registrar from repository to ensure it's attached and has all fields
        Registrar registrar = registrarRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));

        String token = jwtUtils.generateToken(authentication);
        long expiresIn = jwtUtils.getExpirationTime();

        UserResponse userResponse = UserResponse.builder()
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

        log.info("Login successful: {}", request.getUsername());

        return LoginResponse.builder()
                .token(token)
                .expiresIn(expiresIn)
                .user(userResponse)
                .build();
    }

    @Transactional(readOnly = true)
    public UserResponse getCurrentRegistrar() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
        Registrar registrar = registrarRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));

        return UserResponse.builder()
                .id(registrar.getId())
                .maNhanVien(registrar.getRegistrarCode())
                .hoTen(registrar.getFullName())
                .email(registrar.getEmail())
                .soDienThoai(registrar.getPhone())
                .roleId(registrar.getRole().getId())
                .roleName(registrar.getRole().getRoleName())
                .roleDisplayName(registrar.getRole().getDisplayName())
                .quayId(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getId() : null)
                .tenQuay(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getDeskName() : null)
                .trangThai(registrar.getIsActive())
                .ngayTao(registrar.getCreatedAt())
                .build();
    }

    @Transactional
    public UserResponse updateProfile(UpdateProfileRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
        Registrar registrar = registrarRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));

        if (request.getHoTen() != null)
            registrar.setFullName(request.getHoTen());
        if (request.getEmail() != null)
            registrar.setEmail(request.getEmail());
        if (request.getSoDienThoai() != null)
            registrar.setPhone(request.getSoDienThoai());

        registrar = registrarRepository.save(registrar);
        log.info("Profile updated: {}", registrar.getRegistrarCode());

        return UserResponse.builder()
                .id(registrar.getId())
                .maNhanVien(registrar.getRegistrarCode())
                .hoTen(registrar.getFullName())
                .email(registrar.getEmail())
                .soDienThoai(registrar.getPhone())
                .roleId(registrar.getRole().getId())
                .roleName(registrar.getRole().getRoleName())
                .roleDisplayName(registrar.getRole().getDisplayName())
                .quayId(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getId() : null)
                .tenQuay(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getDeskName() : null)
                .trangThai(registrar.getIsActive())
                .ngayTao(registrar.getCreatedAt())
                .build();
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
        Registrar registrar = registrarRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), registrar.getPasswordHash())) {
            throw new RuntimeException("Mật khẩu hiện tại không đúng");
        }

        registrar.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        registrarRepository.save(registrar);
        log.info("Password changed: {}", registrar.getRegistrarCode());
    }
}
