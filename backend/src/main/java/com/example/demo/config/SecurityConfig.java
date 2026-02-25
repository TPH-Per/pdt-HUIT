package com.example.demo.config;

import com.example.demo.security.JwtAuthenticationFilter;
import com.example.demo.service.CustomUserDetailsService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfigurationSource;

/**
 * Cấu hình Spring Security
 * 
 * Đây là file QUAN TRỌNG NHẤT cho security:
 * - Định nghĩa URL nào cần auth, URL nào public
 * - Cấu hình JWT filter
 * - Cấu hình password encoder
 */
@Configuration
@EnableWebSecurity // Bật Spring Security
@EnableMethodSecurity // Cho phép dùng @PreAuthorize trên method
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;
    private final CustomUserDetailsService userDetailsService;
    private final CorsConfigurationSource corsConfigurationSource;

    /**
     * Cấu hình Security Filter Chain
     * 
     * Đây là nơi định nghĩa TẤT CẢ rules bảo mật
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // 1. Enable CORS
                .cors(cors -> cors.configurationSource(corsConfigurationSource))

                // 2. Disable CSRF - không cần vì dùng JWT (stateless)
                .csrf(AbstractHttpConfigurer::disable)

                // 3. Cấu hình authorization cho các URLs
                .authorizeHttpRequests(auth -> auth
                        // URLs PUBLIC - không cần đăng nhập
                        .requestMatchers(
                                "/api/auth/**", // Login, register
                                "/api/public/**", // Public endpoints
                                "/api/student/**", // Student self-service APIs
                                "/error", // Error page
                                "/actuator/health" // Health check
                        ).permitAll()

                        // URLs chỉ ADMIN mới được truy cập
                        .requestMatchers("/api/admin/**").hasRole("Admin")

                        // URLs Cán bộ đào tạo hoặc ADMIN đều được truy cập
                        .requestMatchers("/api/registrar/**").hasAnyRole("Admin", "Registrar")

                        // Tất cả URLs còn lại phải đăng nhập
                        .anyRequest().authenticated())

                // 4. Session Management - STATELESS vì dùng JWT
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // 5. Cấu hình Authentication Provider
                .authenticationProvider(authenticationProvider())

                // 6. Thêm JWT Filter TRƯỚC UsernamePasswordAuthenticationFilter
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * Password Encoder - dùng BCrypt
     * 
     * BCrypt là thuật toán hash password AN TOÀN:
     * - Tự động thêm salt
     * - Chậm (chống brute force)
     * - Không thể reverse
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Authentication Provider
     * 
     * Kết nối UserDetailsService với PasswordEncoder
     * để Spring Security biết cách verify credentials
     */
    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    /**
     * Authentication Manager
     * 
     * Bean này được AuthService inject để authenticate user
     */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config)
            throws Exception {
        return config.getAuthenticationManager();
    }
}
