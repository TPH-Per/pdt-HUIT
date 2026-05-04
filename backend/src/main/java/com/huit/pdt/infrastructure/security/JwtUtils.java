package com.huit.pdt.infrastructure.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
@Slf4j
public class JwtUtils {

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    private SecretKey getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(java.util.Base64.getEncoder().encodeToString(jwtSecret.getBytes()));
        return Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateToken(Integer userId, String username, String role) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpiration);
        String jti = UUID.randomUUID().toString();

        return Jwts.builder().id(jti).subject(username).claim("userId", userId).claim("role", role).issuedAt(now).expiration(expiryDate).signWith(getSigningKey()).compact();
    }

    public String generateToken(org.springframework.security.core.Authentication authentication) {
        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
        return generateToken(userDetails.getId(), userDetails.getUsername(), userDetails.getRoleName());
    }

    public String generateTokenForStudent(String mssv) {
        return generateToken(null, mssv, "STUDENT");
    }

    public String getUsernameFromToken(String token) {
        return getClaimsFromToken(token).getSubject();
    }

    public Integer getUserIdFromToken(String token) {
        return getClaimsFromToken(token).get("userId", Integer.class);
    }

    public String getRoleFromToken(String token) {
        return getClaimsFromToken(token).get("role", String.class);
    }

    public String getJtiFromToken(String token) {
        return getClaimsFromToken(token).getId();
    }

    public List<GrantedAuthority> getAuthoritiesFromToken(String token) {
        String role = getRoleFromToken(token);
        return List.of(new SimpleGrantedAuthority("ROLE_" + role));
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parser().verifyWith(getSigningKey()).build().parseSignedClaims(token);
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

    private Claims getClaimsFromToken(String token) {
        return Jwts.parser().verifyWith(getSigningKey()).build().parseSignedClaims(token).getPayload();
    }

    public long getExpirationTime() {
        return jwtExpiration;
    }
}
