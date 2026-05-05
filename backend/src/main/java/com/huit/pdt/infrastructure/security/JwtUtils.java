package com.huit.pdt.infrastructure.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.List;
import java.util.UUID;

@Component
@Slf4j
public class JwtUtils {

    private static final String CLAIM_ROLE = "role";
    private static final String CLAIM_USER_ID = "userId";
    private static final String CLAIM_TOKEN_TYPE = "tokenType";
    private static final String ACCESS_TOKEN_TYPE = "ACCESS";
    private static final String REFRESH_TOKEN_TYPE = "REFRESH";

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    @Value("${jwt.refresh-expiration}")
    private long jwtRefreshExpiration;

    private SecretKey getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(java.util.Base64.getEncoder().encodeToString(jwtSecret.getBytes()));
        return Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateToken(Integer userId, String username, String role) {
        return generateToken(userId, username, role, ACCESS_TOKEN_TYPE, jwtExpiration);
    }

    public String generateRefreshToken(Integer userId, String username, String role) {
        return generateToken(userId, username, role, REFRESH_TOKEN_TYPE, jwtRefreshExpiration);
    }

    private String generateToken(Integer userId, String username, String role, String tokenType, long expiration) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expiration);
        String jti = UUID.randomUUID().toString();

        return Jwts.builder()
                .id(jti)
                .subject(username)
                .claim(CLAIM_USER_ID, userId)
                .claim(CLAIM_ROLE, role)
                .claim(CLAIM_TOKEN_TYPE, tokenType)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    public String generateToken(Authentication authentication) {
        return generateTokenFromAuthentication(authentication, ACCESS_TOKEN_TYPE, jwtExpiration);
    }

    public String generateRefreshToken(Authentication authentication) {
        return generateTokenFromAuthentication(authentication, REFRESH_TOKEN_TYPE, jwtRefreshExpiration);
    }

    private String generateTokenFromAuthentication(Authentication authentication, String tokenType, long expiration) {
        Object principal = authentication.getPrincipal();
        if (principal instanceof CustomUserDetails customUserDetails) {
            return generateToken(customUserDetails.getId(), customUserDetails.getUsername(),
                    customUserDetails.getRoleName(), tokenType, expiration);
        }
        if (principal instanceof UserDetails userDetails) {
            String authority = userDetails.getAuthorities().stream()
                    .findFirst()
                    .map(GrantedAuthority::getAuthority)
                    .orElse("ROLE_REGISTRAR");
            String role = authority.startsWith("ROLE_") ? authority.substring(5) : authority;
            return generateToken(null, userDetails.getUsername(), role, tokenType, expiration);
        }
        return generateToken(null, authentication.getName(), "REGISTRAR", tokenType, expiration);
    }

    public String generateTokenForStudent(String mssv) {
        return generateToken(null, mssv, "STUDENT");
    }

    public String getUsernameFromToken(String token) {
        return getClaimsFromToken(token).getSubject();
    }

    public Integer getUserIdFromToken(String token) {
        return getClaimsFromToken(token).get(CLAIM_USER_ID, Integer.class);
    }

    public String getRoleFromToken(String token) {
        return getClaimsFromToken(token).get(CLAIM_ROLE, String.class);
    }

    public String getTokenType(String token) {
        return getClaimsFromToken(token).get(CLAIM_TOKEN_TYPE, String.class);
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

    public boolean validateToken(String token, String expectedTokenType) {
        if (!validateToken(token)) {
            return false;
        }
        String tokenType = getTokenType(token);
        return expectedTokenType.equals(tokenType);
    }

    public Date getExpirationFromToken(String token) {
        return getClaimsFromToken(token).getExpiration();
    }

    private Claims getClaimsFromToken(String token) {
        return Jwts.parser().verifyWith(getSigningKey()).build().parseSignedClaims(token).getPayload();
    }

    public long getExpirationTime() {
        return jwtExpiration;
    }

    public long getRefreshExpirationTime() {
        return jwtRefreshExpiration;
    }

    public String getAccessTokenType() {
        return ACCESS_TOKEN_TYPE;
    }

    public String getRefreshTokenType() {
        return REFRESH_TOKEN_TYPE;
    }
}
