package com.huit.pdt.domain.auth.service;

import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertFalse;

public class PasswordTest {
    @Test
    public void testHashMatchesPassword() {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String rawPassword = "123456";
        String encodedPassword = encoder.encode(rawPassword);
        
        // Verify that the encoded password matches the raw password
        assertTrue(encoder.matches(rawPassword, encodedPassword));
        
        // Verify that a wrong password doesn't match
        assertFalse(encoder.matches("wrongpassword", encodedPassword));
    }
}