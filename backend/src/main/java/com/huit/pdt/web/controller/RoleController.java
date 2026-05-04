package com.huit.pdt.web.controller;

import com.huit.pdt.web.dto.ApiResponse;
import com.huit.pdt.web.dto.RoleResponse;
import com.huit.pdt.infrastructure.persistence.Role;
import com.huit.pdt.infrastructure.persistence.RoleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Role Management Controller cho Admin
 */
@RestController
@RequestMapping("/api/admin/roles")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('Admin')")
public class RoleController {

    private final RoleRepository roleRepository;

    /**
     * Lấy danh sách tất cả roles
     * GET /api/admin/roles
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<RoleResponse>>> getAllRoles() {
        log.info("Getting all roles");

        List<RoleResponse> roles = roleRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(roles));
    }

    /**
     * Lấy role theo ID
     * GET /api/admin/roles/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RoleResponse>> getRoleById(@PathVariable Integer id) {
        Role role = roleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy vai trò với ID: " + id));

        return ResponseEntity.ok(ApiResponse.success(mapToResponse(role)));
    }

    /**
     * Map Role entity to Response DTO
     */
    private RoleResponse mapToResponse(Role role) {
        return RoleResponse.builder()
                .id(role.getId())
                .roleName(role.getRoleName())
                .displayName(role.getDisplayName())
                .description(role.getDescription())
                .build();
    }
}











