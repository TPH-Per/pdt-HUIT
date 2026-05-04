package com.huit.pdt.domain.auth.service;

import com.huit.pdt.web.dto.CreateRegistrarRequest;
import com.huit.pdt.web.dto.UpdateProfileRequest;
import com.huit.pdt.web.dto.RegistrarResponse;
import com.huit.pdt.infrastructure.persistence.Registrar;
import com.huit.pdt.infrastructure.persistence.Role;
import com.huit.pdt.infrastructure.persistence.ServiceDesk;
import com.huit.pdt.infrastructure.persistence.RegistrarRepository;
import com.huit.pdt.infrastructure.persistence.RoleRepository;
import com.huit.pdt.infrastructure.persistence.ServiceDeskRepository;
import com.huit.pdt.infrastructure.security.CustomUserDetails;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service quản lý Cán bộ đào tạo — Hệ thống quản lý Phòng Đào tạo
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class RegistrarService {

    private final RegistrarRepository registrarRepository;
    private final RoleRepository roleRepository;
    private final ServiceDeskRepository serviceDeskRepository;
    private final PasswordEncoder passwordEncoder;

    public RegistrarResponse createRegistrar(CreateRegistrarRequest request) {
        if (registrarRepository.existsByRegistrarCode(request.getRegistrarCode())) {
            throw new RuntimeException("Mã cán bộ đã tồn tại: " + request.getRegistrarCode());
        }
        if (request.getEmail() != null && registrarRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email đã tồn tại: " + request.getEmail());
        }

        Role role = roleRepository.findById(request.getRoleId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy vai trò"));

        ServiceDesk desk = null;
        if (request.getDeskId() != null) {
            desk = serviceDeskRepository.findById(request.getDeskId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy quầy"));
        }

        Registrar registrar = Registrar.builder()
                .registrarCode(request.getRegistrarCode())
                .fullName(request.getFullName())
                .email(request.getEmail())
                .phone(request.getPhone())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(role)
                .serviceDesk(desk)
                .isActive(true)
                .build();

        registrar = registrarRepository.save(registrar);
        log.info("Registrar created: {}", registrar.getRegistrarCode());
        return mapToResponse(registrar);
    }

    @Transactional(readOnly = true)
    public List<RegistrarResponse> getAllRegistrars() {
        return registrarRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<RegistrarResponse> getAllActiveRegistrars() {
        return registrarRepository.findAllActive().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public RegistrarResponse getRegistrarById(Integer id) {
        Registrar registrar = registrarRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ với ID: " + id));
        return mapToResponse(registrar);
    }

    @Transactional(readOnly = true)
    public RegistrarResponse getRegistrarByCode(String code) {
        Registrar registrar = registrarRepository.findByRegistrarCode(code)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ: " + code));
        return mapToResponse(registrar);
    }

    public void changePassword(String oldPassword, String newPassword) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
        Registrar registrar = registrarRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));

        if (!passwordEncoder.matches(oldPassword, registrar.getPasswordHash())) {
            throw new RuntimeException("Mật khẩu hiện tại không đúng");
        }
        registrar.setPasswordHash(passwordEncoder.encode(newPassword));
        registrarRepository.save(registrar);
        log.info("Password changed: {}", registrar.getRegistrarCode());
    }

    public void resetPassword(Integer registrarId, String newPassword) {
        Registrar registrar = registrarRepository.findById(registrarId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));
        registrar.setPasswordHash(passwordEncoder.encode(newPassword));
        registrarRepository.save(registrar);
        log.info("Password reset: {}", registrar.getRegistrarCode());
    }

    public RegistrarResponse updateProfile(UpdateProfileRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
        Registrar registrar = registrarRepository.findById(userDetails.getId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));

        if (request.getHoTen() != null)
            registrar.setFullName(request.getHoTen());
        if (request.getEmail() != null)
            registrar.setEmail(request.getEmail());
        if (request.getSoDienThoai() != null)
            registrar.setPhone(request.getSoDienThoai());

        registrar = registrarRepository.save(registrar);
        log.info("Profile updated: {}", registrar.getRegistrarCode());
        return mapToResponse(registrar);
    }

    public RegistrarResponse toggleActive(Integer registrarId) {
        Registrar registrar = registrarRepository.findById(registrarId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));
        registrar.setIsActive(!registrar.getIsActive());
        registrar = registrarRepository.save(registrar);
        log.info("Toggle active: {} -> {}", registrar.getRegistrarCode(), registrar.getIsActive());
        return mapToResponse(registrar);
    }

    public void deleteRegistrar(Integer registrarId) {
        Registrar registrar = registrarRepository.findById(registrarId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ"));
        registrar.setIsActive(false);
        registrarRepository.save(registrar);
        log.info("Registrar deactivated: {}", registrar.getRegistrarCode());
    }

    private RegistrarResponse mapToResponse(Registrar registrar) {
        return RegistrarResponse.builder()
                .id(registrar.getId())
                .registrarCode(registrar.getRegistrarCode())
                .fullName(registrar.getFullName())
                .email(registrar.getEmail())
                .phone(registrar.getPhone())
                .roleId(registrar.getRole() != null ? registrar.getRole().getId() : null)
                .roleName(registrar.getRole() != null ? registrar.getRole().getRoleName() : null)
                .roleDisplayName(registrar.getRole() != null ? registrar.getRole().getDisplayName() : null)
                .deskId(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getId() : null)
                .deskName(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getDeskName() : null)
                .isActive(registrar.getIsActive())
                .createdAt(registrar.getCreatedAt())
                .build();
    }
}












