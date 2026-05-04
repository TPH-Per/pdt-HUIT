package com.huit.pdt.infrastructure.security;

import com.huit.pdt.domain.auth.service.StudentUserDetailsService;
import com.huit.pdt.domain.auth.service.RegistrarUserDetailsService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * JWT Authentication Filter
 * 
 * Filter này chạy MỖI REQUEST để kiểm tra JWT token.
 * 
 * Flow:
 * 1. Request đến → Filter chạy
 * 2. Lấy token từ header "Authorization: Bearer xxx"
 * 3. Validate token
 * 4. Nếu hợp lệ → Set Authentication vào SecurityContext
 * 5. Request tiếp tục đến Controller
 * 
 * OncePerRequestFilter: Đảm bảo filter chỉ chạy 1 lần mỗi request
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    private final JwtUtils jwtUtils;
    private final StudentUserDetailsService studentUserDetailsService;
    private final RegistrarUserDetailsService registrarUserDetailsService;
    
    /**
     * Method chính - được gọi mỗi request
     */
    @Override
    protected void doFilterInternal(HttpServletRequest request, 
                                    HttpServletResponse response, 
                                    FilterChain filterChain) 
            throws ServletException, IOException {
        
        try {
            // Bước 1: Lấy JWT token từ header
            String jwt = getJwtFromRequest(request);
            
            // Bước 2: Kiểm tra token có tồn tại và hợp lệ không
            if (StringUtils.hasText(jwt) && jwtUtils.validateToken(jwt)) {
                
                // Bước 3: Lấy username và role từ token
                String username = jwtUtils.getUsernameFromToken(jwt);
                String role = jwtUtils.getRoleFromToken(jwt);
                
                // Bước 4: Load user details từ database dựa trên role
                UserDetails userDetails = null;
                
                if ("STUDENT".equals(role)) {
                    try {
                        userDetails = studentUserDetailsService.loadUserByUsername(username);
                    } catch (UsernameNotFoundException e) {
                        log.warn("Student not found: {}", username);
                    }
                } else {
                    try {
                        userDetails = registrarUserDetailsService.loadUserByUsername(username);
                    } catch (UsernameNotFoundException e) {
                        log.warn("Registrar not found: {}", username);
                    }
                }
                
                // Bước 5: Nếu user được tìm thấy, tạo Authentication
                if (userDetails != null) {
                    UsernamePasswordAuthenticationToken authentication = 
                        new UsernamePasswordAuthenticationToken(
                            userDetails,           // Principal: thông tin user
                            null,                  // Credentials: null vì đã verify qua JWT
                            userDetails.getAuthorities()  // Authorities: roles/permissions
                        );
                    
                    // Thêm thông tin request vào authentication
                    authentication.setDetails(
                        new WebAuthenticationDetailsSource().buildDetails(request)
                    );
                    
                    // Bước 6: Set Authentication vào SecurityContext
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                    
                    log.debug("Authenticated user: {} with role: {}", username, role);
                }
            }
        } catch (Exception e) {
            log.error("Cannot set user authentication: {}", e.getMessage());
        }
        
        // Bước 7: Tiếp tục filter chain (đến filter tiếp theo hoặc Controller)
        filterChain.doFilter(request, response);
    }
    
    /**
     * Lấy JWT token từ Authorization header
     * 
     * Header format: "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..."
     * 
     * @return JWT token string hoặc null nếu không có
     */
    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        
        // Kiểm tra header có tồn tại và bắt đầu bằng "Bearer "
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            // Cắt bỏ "Bearer " (7 ký tự) để lấy token
            return bearerToken.substring(7);
        }
        
        return null;
    }
}











