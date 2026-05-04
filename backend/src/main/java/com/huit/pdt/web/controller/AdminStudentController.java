package com.huit.pdt.web.controller;

import com.huit.pdt.infrastructure.persistence.Student;
import com.huit.pdt.infrastructure.persistence.StudentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/students")
@RequiredArgsConstructor
@Slf4j
public class AdminStudentController {

    private final StudentRepository studentRepository;
    private final PasswordEncoder passwordEncoder;

    // Default password for new students created by admin
    private static final String DEFAULT_PASSWORD = "123456";

    @GetMapping
    @PreAuthorize("hasAnyRole('Admin', 'Registrar')")
    public ResponseEntity<List<Student>> getAllStudents() {
        return ResponseEntity.ok(studentRepository.findAll());
    }

    @GetMapping("/{mssv}")
    @PreAuthorize("hasAnyRole('Admin', 'Registrar')")
    public ResponseEntity<Student> getStudentById(@PathVariable String mssv) {
        return studentRepository.findByStudentId(mssv)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('Admin', 'Registrar')")
    @Transactional
    public ResponseEntity<Map<String, Object>> createStudent(@RequestBody Map<String, String> body) {
        String mssv = body.get("studentId");
        String fullName = body.get("fullName");

        if (mssv == null || fullName == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "MSSV và Họ tên là bắt buộc"));
        }

        if (studentRepository.findByStudentId(mssv).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("error", "MSSV đã tồn tại"));
        }

        Student student = Student.builder()
                .studentId(mssv)
                .fullName(fullName)
                .major(body.get("major"))
                .gender(body.get("gender"))
                .phone(body.get("phone"))
                .email(body.get("email"))
                .passwordHash(passwordEncoder.encode(DEFAULT_PASSWORD)) // Hash default pass
                .build();

        if (body.get("dateOfBirth") != null && !body.get("dateOfBirth").trim().isEmpty()) {
            student.setDateOfBirth(java.time.LocalDate.parse(body.get("dateOfBirth")));
        }

        studentRepository.save(student);
        log.info("Admin created student: {}", mssv);

        return ResponseEntity.ok(Map.of("message", "Đã khởi tạo sinh viên", "data", student));
    }

    @PutMapping("/{mssv}")
    @PreAuthorize("hasAnyRole('Admin', 'Registrar')")
    @Transactional
    public ResponseEntity<Map<String, Object>> updateStudent(
            @PathVariable String mssv,
            @RequestBody Map<String, String> body) {

        Student student = studentRepository.findByStudentId(mssv).orElse(null);
        if (student == null) {
            return ResponseEntity.notFound().build();
        }

        if (body.containsKey("fullName"))
            student.setFullName(body.get("fullName"));
        if (body.containsKey("major"))
            student.setMajor(body.get("major"));
        if (body.containsKey("gender"))
            student.setGender(body.get("gender"));
        if (body.containsKey("phone"))
            student.setPhone(body.get("phone"));
        if (body.containsKey("email"))
            student.setEmail(body.get("email"));

        if (body.containsKey("dateOfBirth")) {
            String dob = body.get("dateOfBirth");
            if (dob == null || dob.trim().isEmpty()) {
                student.setDateOfBirth(null);
            } else {
                student.setDateOfBirth(java.time.LocalDate.parse(dob));
            }
        }

        studentRepository.save(student);
        log.info("Admin updated student: {}", mssv);

        return ResponseEntity.ok(Map.of("message", "Cập nhật thành công", "data", student));
    }

    @DeleteMapping("/{mssv}")
    @PreAuthorize("hasAnyRole('Admin', 'Registrar')")
    @Transactional
    public ResponseEntity<Map<String, String>> deleteStudent(@PathVariable String mssv) {
        if (!studentRepository.existsById(mssv)) {
            return ResponseEntity.notFound().build();
        }

        try {
            studentRepository.deleteById(mssv);
            log.info("Admin deleted student: {}", mssv);
            return ResponseEntity.ok(Map.of("message", "Xóa sinh viên thành công"));
        } catch (Exception ex) {
            return ResponseEntity.status(409).body(Map.of(
                    "error", "Không thể xóa sinh viên do ràng buộc dữ liệu (hồ sơ, lịch hẹn, ...)"));
        }
    }

    @PostMapping("/{mssv}/reset-password")
    @PreAuthorize("hasAnyRole('Admin', 'Registrar')")
    @Transactional
    public ResponseEntity<Map<String, String>> resetPassword(
            @PathVariable String mssv,
            @RequestBody Map<String, String> body) {

        return studentRepository.findByStudentId(mssv)
                .map(student -> {
                    String newPass = body.getOrDefault("newPassword", DEFAULT_PASSWORD);
                    student.setPasswordHash(passwordEncoder.encode(newPass));
                    studentRepository.save(student);
                    log.info("Admin reset password for student: {}", mssv);
                    return ResponseEntity.ok(Map.of("message", "Đã đặt lại mật khẩu thành công"));
                })
                .orElse(ResponseEntity.notFound().build());
    }
}










