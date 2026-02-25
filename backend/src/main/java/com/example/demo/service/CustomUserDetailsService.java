package com.example.demo.service;

import com.example.demo.entity.Registrar;
import com.example.demo.repository.RegistrarRepository;
import com.example.demo.security.CustomUserDetails;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service load thông tin cán bộ đào tạo cho Spring Security
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CustomUserDetailsService implements UserDetailsService {

    private final RegistrarRepository registrarRepository;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String registrarCode) throws UsernameNotFoundException {
        log.debug("Loading user by registrar code: {}", registrarCode);

        Registrar registrar = registrarRepository.findByRegistrarCode(registrarCode)
                .orElseThrow(() -> {
                    log.error("Registrar not found: {}", registrarCode);
                    return new UsernameNotFoundException("Không tìm thấy cán bộ: " + registrarCode);
                });

        if (!registrar.getIsActive()) {
            log.warn("Inactive registrar login attempt: {}", registrarCode);
            throw new UsernameNotFoundException("Tài khoản đã bị khóa: " + registrarCode);
        }

        log.debug("Registrar loaded successfully: {}", registrarCode);
        return new CustomUserDetails(registrar);
    }

    @Transactional(readOnly = true)
    public UserDetails loadUserById(Integer id) {
        Registrar registrar = registrarRepository.findById(id)
                .orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy cán bộ với ID: " + id));
        return new CustomUserDetails(registrar);
    }
}
