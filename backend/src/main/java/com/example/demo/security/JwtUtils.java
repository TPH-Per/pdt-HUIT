package com.example.demo.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.UUID;

/**
 * Utility class để làm việc với JWT Token
 * 
 * JWT (JSON Web Token) gồm 3 phần:
 * 1. Header: Thông tin thuật toán mã hóa
 * 2. Payload: Dữ liệu (user id, username, roles, expiration...)
 * 3. Signature: Chữ ký để verify token
 * 
 * Ví dụ JWT: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJOVjAwMSJ9.abc123...
 */
@Component
@Slf4j
public class JwtUtils {

    /**
     * Secret key để ký và verify token
     * Đọc từ application.properties: jwt.secret
     * 
     * @Value: Spring sẽ inject giá trị từ config file
     */
    @Value("${jwt.secret}")
    private String jwtSecret;

    /**
     * Thời gian token hết hạn (milliseconds)
     * Đọc từ application.properties: jwt.expiration
     */
    @Value("${jwt.expiration}")
    private long jwtExpiration;

    /**
     * Tạo SecretKey từ chuỗi secret
     * 
     * Keys.hmacShaKeyFor(): Tạo key cho thuật toán HMAC-SHA
     */
    private SecretKey getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(
                java.util.Base64.getEncoder().encodeToString(jwtSecret.getBytes()));
        return Keys.hmacShaKeyFor(keyBytes);
    }

    /**
     * Tạo JWT token từ thông tin user
     * 
     * @param userId   ID của user trong database
     * @param username Mã nhân viên (dùng làm subject)
     * @param role     Tên role của user
     * @return JWT token string
     */
    public String generateToken(Integer userId, String username, String role) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpiration);

        // Tạo JTI (JWT ID) - định danh duy nhất cho mỗi token
        // Dùng UUID để đảm bảo không trùng lặp trên toàn cầu
        String jti = UUID.randomUUID().toString();

        return Jwts.builder()
                .id(jti) // JTI: JWT ID - định danh duy nhất
                .subject(username) // Subject: ai sở hữu token
                .claim("userId", userId) // Custom claim: user ID
                .claim("role", role) // Custom claim: role name
                .issuedAt(now) // Thời gian tạo
                .expiration(expiryDate) // Thời gian hết hạn
                .signWith(getSigningKey()) // Ký bằng secret key
                .compact(); // Build thành string
    }

    /**
     * Generate token from Spring Security Authentication
     */
    public String generateToken(org.springframework.security.core.Authentication authentication) {
        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
        return generateToken(
                userDetails.getId(),
                userDetails.getUsername(),
                userDetails.getRoleName());
    }

    /**
     * Lấy username (subject) từ token
     */
    public String getUsernameFromToken(String token) {
        return getClaimsFromToken(token).getSubject();
    }

    /**
     * Lấy user ID từ token
     */
    public Integer getUserIdFromToken(String token) {
        return getClaimsFromToken(token).get("userId", Integer.class);
    }

    /**
     * Lấy role từ token
     */
    public String getRoleFromToken(String token) {
        return getClaimsFromToken(token).get("role", String.class);
    }

    /**
     * Lấy JTI (JWT ID) từ token
     * 
     * JTI dùng để:
     * - Định danh duy nhất mỗi token
     * - Có thể dùng để revoke token (lưu JTI vào blacklist)
     * - Tracking token usage
     */
    public String getJtiFromToken(String token) {
        return getClaimsFromToken(token).getId();
    }

    /**
     * Kiểm tra token có hợp lệ không
     * 
     * Token hợp lệ khi:
     * - Chữ ký đúng (không bị sửa đổi)
     * - Chưa hết hạn
     * - Định dạng đúng
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(getSigningKey()) // Verify chữ ký
                    .build()
                    .parseSignedClaims(token); // Parse và validate
            return true;
        } catch (MalformedJwtException e) {
            log.error("Token không đúng định dạng: {}", e.getMessage());
        } catch (ExpiredJwtException e) {
            log.error("Token đã hết hạn: {}", e.getMessage());
        } catch (UnsupportedJwtException e) {
            log.error("Token không được hỗ trợ: {}", e.getMessage());
        } catch (IllegalArgumentException e) {
            log.error("Token rỗng: {}", e.getMessage());
        } catch (SecurityException e) {
            log.error("Chữ ký token không hợp lệ: {}", e.getMessage());
        }
        return false;
    }

    /**
     * Parse token và lấy Claims (payload)
     * 
     * Claims chứa tất cả data trong token:
     * - subject: username
     * - userId: custom claim
     * - role: custom claim
     * - iat: issued at (thời gian tạo)
     * - exp: expiration (thời gian hết hạn)
     */
    private Claims getClaimsFromToken(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * Lấy thời gian hết hạn của token (milliseconds)
     */
    public long getExpirationTime() {
        return jwtExpiration;
    }
}
