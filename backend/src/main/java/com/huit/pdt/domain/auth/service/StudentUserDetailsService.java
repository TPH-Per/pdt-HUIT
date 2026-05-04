package com.huit.pdt.domain.auth.service;

import com.huit.pdt.infrastructure.persistence.Student;
import com.huit.pdt.infrastructure.persistence.StudentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.core.userdetails.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collection;

/**
 * Load student user details for Spring Security authentication
 * Students authenticate using their MSSV (student ID)
 */
@Service("studentUserDetailsService")
@RequiredArgsConstructor
@Slf4j
public class StudentUserDetailsService implements UserDetailsService {

    private final StudentRepository studentRepository;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String studentId) throws UsernameNotFoundException {
        log.debug("Loading student by student ID: {}", studentId);

        Student student = studentRepository.findByStudentId(studentId)
                .orElseThrow(() -> {
                    log.error("Student not found: {}", studentId);
                    return new UsernameNotFoundException("Không tìm thấy sinh viên: " + studentId);
                });

        // Create a list of authorities for the student
        Collection<GrantedAuthority> authorities = new ArrayList<>();
        authorities.add(new SimpleGrantedAuthority("ROLE_STUDENT"));

        log.debug("Student loaded successfully: {}", studentId);
        
        // Create UserDetails using Spring's User builder
        return User.builder()
                .username(student.getStudentId())
                .password(student.getPasswordHash())
                .authorities(authorities)
                .accountExpired(false)
                .accountLocked(false)
                .credentialsExpired(false)
                .disabled(false)
                .build();
    }

    @Transactional(readOnly = true)
    public UserDetails loadUserByStudentId(String studentId) {
        return loadUserByUsername(studentId);
    }
}






