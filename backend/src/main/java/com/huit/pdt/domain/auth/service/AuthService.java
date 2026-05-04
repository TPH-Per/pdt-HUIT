package com.huit.pdt.domain.auth.service;

import com.huit.pdt.web.dto.LoginRequest;
import com.huit.pdt.web.dto.ChangePasswordRequest;
import com.huit.pdt.web.dto.UpdateProfileRequest;
import com.huit.pdt.web.dto.LoginResponse;
import com.huit.pdt.web.dto.UserResponse;
import com.huit.pdt.infrastructure.persistence.Registrar;
import com.huit.pdt.infrastructure.persistence.RegistrarRepository;
import com.huit.pdt.infrastructure.security.CustomUserDetails;
import com.huit.pdt.infrastructure.security.JwtUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

        Authentication authentication = authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);

        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();

        Registrar registrar = registrarRepository.findById(userDetails.getId()).orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));

        String token = jwtUtils.generateToken(authentication);
        long expiresIn = jwtUtils.getExpirationTime();

        UserResponse userResponse = UserResponse.builder().id(registrar.getId()).maNhanVien(registrar.getRegistrarCode()).hoTen(registrar.getFullName()).email(registrar.getEmail()).soDienThoai(registrar.getPhone()).roleId(registrar.getRole() != null ? registrar.getRole().getId() : null).roleName(registrar.getRole() != null ? registrar.getRole().getRoleName() : null).roleDisplayName(registrar.getRole() != null ? registrar.getRole().getDisplayName() : null).quayId(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getId() : null).tenQuay(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getDeskName() : null).trangThai(registrar.getIsActive()).ngayTao(registrar.getCreatedAt()).build();

        log.info("Login successful: {}", request.getUsername());

        return LoginResponse.builder().token(token).expiresIn(expiresIn).user(userResponse).build();
    }

    @Transactional(readOnly = true)
    public LoginResponse refreshToken(String refreshToken) {
        if (!jwtUtils.validateToken(refreshToken)) {
            throw new RuntimeException("Invalid refresh token");
        }

        String username = jwtUtils.getUsernameFromToken(refreshToken);
        Registrar registrar = registrarRepository.findByRegistrarCode(username).orElseThrow(() -> new RuntimeException("User not found"));

        Authentication authentication = new UsernamePasswordAuthenticationToken(username, null, jwtUtils.getAuthoritiesFromToken(refreshToken));
        String newToken = jwtUtils.generateToken(authentication);
        long expiresIn = jwtUtils.getExpirationTime();

        UserResponse userResponse = UserResponse.builder().id(registrar.getId()).maNhanVien(registrar.getRegistrarCode()).hoTen(registrar.getFullName()).email(registrar.getEmail()).soDienThoai(registrar.getPhone()).roleId(registrar.getRole() != null ? registrar.getRole().getId() : null).roleName(registrar.getRole() != null ? registrar.getRole().getRoleName() : null).roleDisplayName(registrar.getRole() != null ? registrar.getRole().getDisplayName() : null).quayId(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getId() : null).tenQuay(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getDeskName() : null).trangThai(registrar.getIsActive()).ngayTao(registrar.getCreatedAt()).build();

        log.info("Token refreshed for: {}", username);

        return LoginResponse.builder().token(newToken).expiresIn(expiresIn).user(userResponse).build();
    }

    @Transactional
    public void logout(String token) {
        String username = jwtUtils.getUsernameFromToken(token);
        log.info("User logged out: {}", username);
        SecurityContextHolder.clearContext();
    }

    @Transactional(readOnly = true)
    public UserResponse getCurrentRegistrar() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
        Registrar registrar = registrarRepository.findById(userDetails.getId()).orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));

        return UserResponse.builder().id(registrar.getId()).maNhanVien(registrar.getRegistrarCode()).hoTen(registrar.getFullName()).email(registrar.getEmail()).soDienThoai(registrar.getPhone()).roleId(registrar.getRole().getId()).roleName(registrar.getRole().getRoleName()).roleDisplayName(registrar.getRole().getDisplayName()).quayId(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getId() : null).tenQuay(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getDeskName() : null).trangThai(registrar.getIsActive()).ngayTao(registrar.getCreatedAt()).build();
    }

    @Transactional
    public UserResponse updateProfile(UpdateProfileRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
        Registrar registrar = registrarRepository.findById(userDetails.getId()).orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));

        if (request.getHoTen() != null) registrar.setFullName(request.getHoTen());
        if (request.getEmail() != null) registrar.setEmail(request.getEmail());
        if (request.getSoDienThoai() != null) registrar.setPhone(request.getSoDienThoai());

        registrar = registrarRepository.save(registrar);
        log.info("Profile updated: {}", registrar.getRegistrarCode());

        return UserResponse.builder().id(registrar.getId()).maNhanVien(registrar.getRegistrarCode()).hoTen(registrar.getFullName()).email(registrar.getEmail()).soDienThoai(registrar.getPhone()).roleId(registrar.getRole().getId()).roleName(registrar.getRole().getRoleName()).roleDisplayName(registrar.getRole().getDisplayName()).quayId(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getId() : null).tenQuay(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getDeskName() : null).trangThai(registrar.getIsActive()).ngayTao(registrar.getCreatedAt()).build();
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
        Registrar registrar = registrarRepository.findById(userDetails.getId()).orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), registrar.getPasswordHash())) {
            throw new RuntimeException("Mật khẩu hiện tại không đúng");
        }

        registrar.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        registrarRepository.save(registrar);
        log.info("Password changed: {}", registrar.getRegistrarCode());
    }
}
