package com.huit.pdt.web.controller;

import com.huit.pdt.web.dto.ApiResponse;
import com.huit.pdt.web.dto.LoginResponse;
import com.huit.pdt.infrastructure.persistence.Student;
import com.huit.pdt.infrastructure.persistence.StudentRepository;
import com.huit.pdt.infrastructure.security.JwtUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * Student Auth Controller – Xác thực sinh viên
 * POST /api/student/auth/login → Đăng nhập bằng MSSV + mật khẩu
 * POST /api/student/auth/register → Đăng ký tài khoản sinh viên
 * POST /api/student/auth/change-password → Đổi mật khẩu
 */
@RestController
@RequestMapping("/api/student/auth")
@RequiredArgsConstructor
@Slf4j
public class StudentAuthController {

    private final StudentRepository studentRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;

    // ==================== ĐĂNG NHẬP ====================
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<Map<String, Object>>> login(@RequestBody Map<String, String> body) {
        String mssv = body.get("mssv");
        String password = body.get("password");

        if (mssv == null || password == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("MISSING_FIELDS", "Vui lòng nhập MSSV và mật khẩu"));
        }

        Student student = studentRepository.findByStudentId(mssv).orElse(null);
        if (student == null) {
            return ResponseEntity.status(401)
                    .body(ApiResponse.error("INVALID_CREDENTIALS", "MSSV không tồn tại"));
        }

        log.debug("Student found: {}, hashType: {}, encoder: {}", mssv, student.getPasswordHash().substring(0, Math.min(10, student.getPasswordHash().length())), passwordEncoder.getClass().getName());
        boolean passwordMatches = passwordEncoder.matches(password, student.getPasswordHash());
        log.debug("Password matches: {}", passwordMatches);
        
        if (!passwordMatches) {
            return ResponseEntity.status(401)
                    .body(ApiResponse.error("INVALID_CREDENTIALS", "Mật khẩu không đúng"));
        }

        log.info("Student login success: {}", mssv);
        
        // Generate JWT token for student
        String token = jwtUtils.generateTokenForStudent(mssv);
        long expiresIn = jwtUtils.getExpirationTime();
        
        // Build response with token
        Map<String, Object> response = new HashMap<>();
        response.put("token", token);
        response.put("tokenType", "Bearer");
        response.put("expiresIn", expiresIn);
        response.put("user", buildStudentProfile(student));
        
        return ResponseEntity.ok(ApiResponse.success(response, "Đăng nhập thành công"));
    }

    // ==================== ĐĂNG KÝ ====================
    @PostMapping("/register")
    @Transactional
    public ResponseEntity<ApiResponse<Map<String, Object>>> register(@RequestBody Map<String, String> body) {
        String mssv = body.get("mssv");
        String fullName = body.get("fullName");
        String password = body.get("password");
        String major = body.get("major");
        String phone = body.get("phone");
        String email = body.get("email");

        if (mssv == null || fullName == null || password == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("MISSING_FIELDS", "Vui lòng nhập MSSV, họ tên và mật khẩu"));
        }

        if (mssv.length() != 10) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_MSSV", "MSSV phải có đúng 10 ký tự"));
        }

        if (password.length() < 6) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("WEAK_PASSWORD", "Mật khẩu phải có ít nhất 6 ký tự"));
        }

        if (studentRepository.findByStudentId(mssv).isPresent()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("MSSV_EXISTS", "MSSV đã được đăng ký"));
        }

        Student student = Student.builder()
                .studentId(mssv)
                .fullName(fullName)
                .major(major)
                .phone(phone)
                .email(email)
                .passwordHash(passwordEncoder.encode(password))
                .build();

        studentRepository.save(student);
        log.info("Student registered: {}", mssv);

        return ResponseEntity.ok(ApiResponse.success(buildStudentProfile(student), "Đăng ký thành công"));
    }

    // ==================== ĐỔI MẬT KHẨU ====================
    @PostMapping("/change-password")
    @Transactional
    public ResponseEntity<ApiResponse<Map<String, String>>> changePassword(@RequestBody Map<String, String> body) {
        String mssv = body.get("mssv");
        String oldPassword = body.get("oldPassword");
        String newPassword = body.get("newPassword");

        if (mssv == null || oldPassword == null || newPassword == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("MISSING_FIELDS", "Vui lòng nhập đầy đủ thông tin"));
        }

        if (newPassword.length() < 6) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("WEAK_PASSWORD", "Mật khẩu mới phải có ít nhất 6 ký tự"));
        }

        Student student = studentRepository.findByStudentId(mssv).orElse(null);
        if (student == null) {
            return ResponseEntity.status(404)
                    .body(ApiResponse.error("NOT_FOUND", "Không tìm thấy sinh viên"));
        }

        if (!passwordEncoder.matches(oldPassword, student.getPasswordHash())) {
            return ResponseEntity.status(401)
                    .body(ApiResponse.error("WRONG_PASSWORD", "Mật khẩu cũ không đúng"));
        }

        student.setPasswordHash(passwordEncoder.encode(newPassword));
        studentRepository.save(student);
        log.info("Password changed for student: {}", mssv);

        return ResponseEntity.ok(ApiResponse.success(
                Map.of("message", "Đổi mật khẩu thành công"),
                "Đổi mật khẩu thành công"));
    }

    // ==================== HELPER ====================
    private Map<String, Object> buildStudentProfile(Student s) {
        Map<String, Object> profile = new HashMap<>();
        profile.put("studentId", s.getStudentId());
        profile.put("fullName", s.getFullName());
        profile.put("major", s.getMajor());
        profile.put("dateOfBirth", s.getDateOfBirth());
        profile.put("gender", s.getGender());
        profile.put("phone", s.getPhone());
        profile.put("email", s.getEmail());
        return profile;
    }
}











