package com.huit.pdt.web.controller;

import com.huit.pdt.web.dto.CreateServiceCategoryDTO;
import com.huit.pdt.web.dto.UpdateServiceCategoryDTO;
import com.huit.pdt.web.dto.ApiResponse;
import com.huit.pdt.web.dto.ServiceCategoryResponse;
import com.huit.pdt.infrastructure.persistence.ServiceCategory;
import com.huit.pdt.infrastructure.persistence.ServiceCategoryRepository;
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
@RequestMapping("/api/admin/categories")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('Admin')")
@Transactional
public class ServiceCategoryController {

    private final ServiceCategoryRepository serviceCategoryRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ServiceCategoryResponse>>> getAllCategories() {
        log.info("Getting all service categories");
        List<ServiceCategoryResponse> types = serviceCategoryRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(types));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceCategoryResponse>> getCategoryById(@PathVariable Integer id) {
        ServiceCategory type = serviceCategoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy danh mục với ID: " + id));
        return ResponseEntity.ok(ApiResponse.success(mapToResponse(type)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ServiceCategoryResponse>> createCategory(
            @Valid @RequestBody CreateServiceCategoryDTO request) {

        log.info("Creating service category: {}", request.getName());

        if (serviceCategoryRepository.existsByName(request.getName())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("DUPLICATE_NAME", "Tên danh mục đã tồn tại: " + request.getName()));
        }

        ServiceCategory type = ServiceCategory.builder()
                .name(request.getName())
                .description(request.getDescription())
                .isActive(true)
                .build();

        type = serviceCategoryRepository.save(type);
        log.info("Service category created: {}", type.getName());

        return ResponseEntity.ok(ApiResponse.success(mapToResponse(type), "Tạo danh mục thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceCategoryResponse>> updateCategory(
            @PathVariable Integer id,
            @RequestBody UpdateServiceCategoryDTO request) {

        ServiceCategory type = serviceCategoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy danh mục với ID: " + id));

        log.info("Updating service category: {}", type.getName());

        if (request.getName() != null) {
            if (!request.getName().equals(type.getName())
                    && serviceCategoryRepository.existsByName(request.getName())) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("DUPLICATE_NAME", "Tên danh mục đã tồn tại"));
            }
            type.setName(request.getName());
        }
        if (request.getDescription() != null)
            type.setDescription(request.getDescription());
        if (request.getIsActive() != null)
            type.setIsActive(request.getIsActive());

        type = serviceCategoryRepository.save(type);
        log.info("Service category updated: {}", type.getName());

        return ResponseEntity.ok(ApiResponse.success(mapToResponse(type), "Cập nhật thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCategory(@PathVariable Integer id) {
        ServiceCategory type = serviceCategoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy danh mục với ID: " + id));

        log.info("Deleting (deactivating) service category: {}", type.getName());
        type.setIsActive(false);
        serviceCategoryRepository.save(type);

        return ResponseEntity.ok(ApiResponse.success(null, "Đã khóa danh mục"));
    }

    private ServiceCategoryResponse mapToResponse(ServiceCategory type) {
        long deskCount = serviceCategoryRepository.countDesksByCategoryId(type.getId());
        long serviceCount = serviceCategoryRepository.countServicesByCategoryId(type.getId());

        return ServiceCategoryResponse.builder()
                .id(type.getId())
                .name(type.getName())
                .description(type.getDescription())
                .isActive(type.getIsActive())
                .createdAt(type.getCreatedAt())
                .deskCount((int) deskCount)
                .serviceCount((int) serviceCount)
                .build();
    }
}











