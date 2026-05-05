package com.huit.pdt.domain.auth.service;

import com.huit.pdt.web.dto.LoginRequest;
import com.huit.pdt.web.dto.ChangePasswordRequest;
import com.huit.pdt.web.dto.UpdateProfileRequest;
import com.huit.pdt.web.dto.LoginResponse;
import com.huit.pdt.web.dto.UserResponse;
import com.huit.pdt.infrastructure.persistence.Registrar;
import com.huit.pdt.infrastructure.persistence.RegistrarRepository;
import com.huit.pdt.infrastructure.security.JwtUtils;
import com.huit.pdt.web.exception.AppException;
import com.huit.pdt.web.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final JwtUtils jwtUtils;
    private final RegistrarRepository registrarRepository;
    private final PasswordEncoder passwordEncoder;
    private final NamedParameterJdbcTemplate jdbc;

    @Transactional
    public LoginResponse login(LoginRequest request) {
        log.info("Login attempt: {}", request.getUsername());

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);

        String username = authentication.getName();
        Registrar registrar = registrarRepository.findByRegistrarCode(username)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND, "Không tìm thấy cán bộ"));
        UserResponse userResponse = buildUserResponse(registrar);
        LoginResponse response = issueTokens(registrar, username, userResponse);

        log.info("Login successful: {}", username);

        return response;
    }

    @Transactional
    public LoginResponse refreshToken(String refreshToken) {
        if (!jwtUtils.validateToken(refreshToken, jwtUtils.getRefreshTokenType())) {
            throw new AppException(ErrorCode.TOKEN_INVALID, "Refresh token không hợp lệ");
        }

        String username = jwtUtils.getUsernameFromToken(refreshToken);
        int affected = jdbc.update("""
                UPDATE refresh_token
                SET revoked = TRUE
                WHERE token = :token
                  AND user_type = 'REGISTRAR'
                  AND revoked = FALSE
                  AND expires_at > NOW()
                """, Map.of("token", refreshToken));
        if (affected == 0) {
            throw new AppException(ErrorCode.TOKEN_INVALID, "Refresh token đã bị thu hồi hoặc hết hạn");
        }

        Registrar registrar = registrarRepository.findByRegistrarCode(username)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND, "User not found"));
        UserResponse userResponse = buildUserResponse(registrar);
        LoginResponse response = issueTokens(registrar, username, userResponse);

        log.info("Token refreshed for: {}", username);

        return response;
    }

    @Transactional
    public void logout(String accessToken, String refreshToken) {
        if (refreshToken != null && !refreshToken.isBlank()) {
            jdbc.update("""
                    UPDATE refresh_token
                    SET revoked = TRUE
                    WHERE token = :token
                      AND user_type = 'REGISTRAR'
                      AND revoked = FALSE
                    """, Map.of("token", refreshToken));
        }

        if (accessToken != null && !accessToken.isBlank() && jwtUtils.validateToken(accessToken)) {
            String username = jwtUtils.getUsernameFromToken(accessToken);
            revokeAllActiveTokens(username);
            log.info("User logged out: {}", username);
        } else if (refreshToken != null && jwtUtils.validateToken(refreshToken, jwtUtils.getRefreshTokenType())) {
            String username = jwtUtils.getUsernameFromToken(refreshToken);
            revokeAllActiveTokens(username);
            log.info("User logged out by refresh token: {}", username);
        }

        SecurityContextHolder.clearContext();
    }

    @Transactional(readOnly = true)
    public UserResponse getCurrentRegistrar() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        Registrar registrar = registrarRepository.findByRegistrarCode(auth.getName())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND, "Không tìm thấy cán bộ"));

        return buildUserResponse(registrar);
    }

    @Transactional
    public UserResponse updateProfile(UpdateProfileRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        Registrar registrar = registrarRepository.findByRegistrarCode(auth.getName())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND, "Không tìm thấy cán bộ"));

        if (request.getHoTen() != null) registrar.setFullName(request.getHoTen());
        if (request.getEmail() != null) registrar.setEmail(request.getEmail());
        if (request.getSoDienThoai() != null) registrar.setPhone(request.getSoDienThoai());

        registrar = registrarRepository.save(registrar);
        log.info("Profile updated: {}", registrar.getRegistrarCode());

        return buildUserResponse(registrar);
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        Registrar registrar = registrarRepository.findByRegistrarCode(auth.getName())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND, "Không tìm thấy cán bộ"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), registrar.getPasswordHash())) {
            throw new AppException(ErrorCode.INVALID_CREDENTIALS, "Mật khẩu hiện tại không đúng");
        }

        registrar.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        registrarRepository.save(registrar);
        log.info("Password changed: {}", registrar.getRegistrarCode());
    }

    private LoginResponse issueTokens(Registrar registrar, String username, UserResponse userResponse) {
        String role = registrar.getRole() != null ? registrar.getRole().getRoleName() : "REGISTRAR";
        String accessToken = jwtUtils.generateToken(registrar.getId(), username, role);
        String refreshToken = jwtUtils.generateRefreshToken(registrar.getId(), username, role);

        revokeAllActiveTokens(username);
        persistRefreshToken(refreshToken, username, jwtUtils.getExpirationFromToken(refreshToken).toInstant()
                .atOffset(OffsetDateTime.now().getOffset()));

        return LoginResponse.builder()
                .token(accessToken)
                .expiresIn(jwtUtils.getExpirationTime())
                .refreshToken(refreshToken)
                .refreshExpiresIn(jwtUtils.getRefreshExpirationTime())
                .user(userResponse)
                .build();
    }

    private void persistRefreshToken(String refreshToken, String username, OffsetDateTime expiresAt) {
        jdbc.update("""
                INSERT INTO refresh_token(token, user_id, user_type, expires_at, revoked)
                VALUES (:token, :userId, 'REGISTRAR', :expiresAt, FALSE)
                """, Map.of("token", refreshToken, "userId", username, "expiresAt", expiresAt));
    }

    private void revokeAllActiveTokens(String username) {
        jdbc.update("""
                UPDATE refresh_token
                SET revoked = TRUE
                WHERE user_id = :userId
                  AND user_type = 'REGISTRAR'
                  AND revoked = FALSE
                """, Map.of("userId", username));
    }

    private UserResponse buildUserResponse(Registrar registrar) {
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
