package com.example.demo.controller;

import com.example.demo.dto.request.CreateServiceDeskDTO;
import com.example.demo.dto.request.UpdateServiceDeskDTO;
import com.example.demo.dto.response.ApiResponse;
import com.example.demo.dto.response.ServiceDeskResponse;
import com.example.demo.entity.ServiceDesk;
import com.example.demo.entity.ServiceCategory;
import com.example.demo.repository.ServiceDeskRepository;
import com.example.demo.repository.ServiceCategoryRepository;
import com.example.demo.repository.RegistrarRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/desks")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('Admin')")
@Transactional
public class ServiceDeskController {

    private final ServiceDeskRepository serviceDeskRepository;
    private final ServiceCategoryRepository serviceCategoryRepository;
    private final RegistrarRepository registrarRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ServiceDeskResponse>>> getAllDesks() {
        log.info("Getting all service desks");
        List<ServiceDeskResponse> desks = serviceDeskRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(desks));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceDeskResponse>> getDeskById(@PathVariable Integer id) {
        ServiceDesk desk = serviceDeskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy quầy với ID: " + id));
        return ResponseEntity.ok(ApiResponse.success(mapToResponse(desk)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ServiceDeskResponse>> createDesk(
            @Valid @RequestBody CreateServiceDeskDTO request) {
        log.info("Creating service desk: {}", request.getDeskCode());

        if (serviceDeskRepository.existsByDeskCode(request.getDeskCode())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("DUPLICATE_CODE", "Mã quầy đã tồn tại: " + request.getDeskCode()));
        }

        ServiceCategory category = null;
        if (request.getCategoryId() != null) {
            category = serviceCategoryRepository.findById(request.getCategoryId())
                    .orElseThrow(
                            () -> new RuntimeException("Không tìm thấy danh mục với ID: " + request.getCategoryId()));
        }

        ServiceDesk desk = ServiceDesk.builder()
                .deskCode(request.getDeskCode())
                .deskName(request.getDeskName())
                .location(request.getLocation())
                .serviceCategory(category)
                .notes(request.getNotes())
                .isActive(true)
                .build();

        desk = serviceDeskRepository.save(desk);
        log.info("Service desk created: {}", desk.getDeskCode());

        return ResponseEntity.ok(ApiResponse.success(mapToResponse(desk), "Tạo quầy thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceDeskResponse>> updateDesk(
            @PathVariable Integer id,
            @RequestBody UpdateServiceDeskDTO request) {

        ServiceDesk desk = serviceDeskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy quầy với ID: " + id));

        log.info("Updating service desk: {}", desk.getDeskCode());

        if (request.getDeskName() != null)
            desk.setDeskName(request.getDeskName());
        if (request.getLocation() != null)
            desk.setLocation(request.getLocation());
        if (request.getCategoryId() != null) {
            ServiceCategory category = serviceCategoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy danh mục"));
            desk.setServiceCategory(category);
        }
        if (request.getNotes() != null)
            desk.setNotes(request.getNotes());
        if (request.getIsActive() != null)
            desk.setIsActive(request.getIsActive());

        desk = serviceDeskRepository.save(desk);
        log.info("Service desk updated: {}", desk.getDeskCode());

        return ResponseEntity.ok(ApiResponse.success(mapToResponse(desk), "Cập nhật thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteDesk(@PathVariable Integer id) {
        ServiceDesk desk = serviceDeskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy quầy với ID: " + id));

        log.info("Deleting (deactivating) service desk: {}", desk.getDeskCode());
        desk.setIsActive(false);
        serviceDeskRepository.save(desk);

        return ResponseEntity.ok(ApiResponse.success(null, "Đã khóa quầy"));
    }

    private ServiceDeskResponse mapToResponse(ServiceDesk desk) {
        long staffCount = registrarRepository.countByDeskId(desk.getId());

        return ServiceDeskResponse.builder()
                .id(desk.getId())
                .deskCode(desk.getDeskCode())
                .deskName(desk.getDeskName())
                .location(desk.getLocation())
                .categoryId(desk.getServiceCategory() != null ? desk.getServiceCategory().getId() : null)
                .categoryName(desk.getServiceCategory() != null ? desk.getServiceCategory().getName() : null)
                .isActive(desk.getIsActive())
                .notes(desk.getNotes())
                .createdAt(desk.getCreatedAt())
                .staffCount((int) staffCount)
                .build();
    }
}
