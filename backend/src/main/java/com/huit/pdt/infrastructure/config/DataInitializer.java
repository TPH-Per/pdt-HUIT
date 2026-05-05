package com.huit.pdt.infrastructure.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.jdbc.core.JdbcTemplate;

@Configuration
@RequiredArgsConstructor
@Slf4j
public class DataInitializer {
    
    private final JdbcTemplate jdbcTemplate;
    private final BCryptPasswordEncoder passwordEncoder;
    
    @Bean
    public ApplicationRunner initializePasswords() {
        return args -> {
            String password = "123456";
            String encodedPassword = passwordEncoder.encode(password);
            
            log.info("Initializing test passwords with hash: {}", encodedPassword);
            
            try {
                // Update all test students with proper hash
                int studentCount = jdbcTemplate.update(
                    "UPDATE student SET password_hash = ? WHERE student_id IN (?, ?, ?)",
                    encodedPassword, "2001215001", "2001215002", "2001215003"
                );
                log.info("Updated {} student records", studentCount);
                
                // Update all test registrars with proper hash
                int registrarCount = jdbcTemplate.update(
                    "UPDATE registrar SET password_hash = ? WHERE registrar_code IN (?, ?, ?, ?)",
                    encodedPassword, "ADMIN", "NV001", "NV002", "NV003"
                );
                log.info("Updated {} registrar records", registrarCount);
                
                // Verify one record
                String verifyHash = jdbcTemplate.queryForObject(
                    "SELECT password_hash FROM student WHERE student_id = ?",
                    String.class,
                    "2001215001"
                );
                
                boolean matches = passwordEncoder.matches(password, verifyHash);
                log.info("Password verification: matches = {}", matches);
                
            } catch (Exception e) {
                log.error("Error initializing passwords", e);
            }
        };
    }
}
