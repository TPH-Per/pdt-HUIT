package com.example.demo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response DTO for successful login
 * 
 * Endpoint: POST /api/auth/login
 * 
 * Example response:
 * {
 * "token": "eyJhbGciOiJIUzI1NiJ9...",
 * "tokenType": "Bearer",
 * "expiresIn": 604800000,
 * "user": { ... }
 * }
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {

    /**
     * JWT token
     */
    private String token;

    /**
     * Token type (always "Bearer")
     */
    @Builder.Default
    private String tokenType = "Bearer";

    /**
     * Expiration time (milliseconds)
     */
    private long expiresIn;

    /**
     * Logged in user info
     */
    private UserResponse user;
}
