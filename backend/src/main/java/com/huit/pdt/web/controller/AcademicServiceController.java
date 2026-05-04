package com.huit.pdt.web.controller;

import com.huit.pdt.web.dto.CreateAcademicServiceDTO;
import com.huit.pdt.web.dto.UpdateAcademicServiceDTO;
import com.huit.pdt.web.dto.ApiResponse;
import com.huit.pdt.web.dto.AcademicServiceResponse;
import com.huit.pdt.infrastructure.persistence.AcademicService;
import com.huit.pdt.infrastructure.persistence.ServiceCategory;
import com.huit.pdt.infrastructure.persistence.AcademicServiceRepository;
import com.huit.pdt.infrastructure.persistence.RequestRepository;
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
@RequestMapping("/api/admin/services")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('Admin')")
@Transactional
public class AcademicServiceController {

    private final AcademicServiceRepository academicServiceRepository;
    private final ServiceCategoryRepository serviceCategoryRepository;
    private final RequestRepository requestRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<AcademicServiceResponse>>> getAllServices() {
        log.info("Getting all academic services");
        List<AcademicServiceResponse> services = academicServiceRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(services));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AcademicServiceResponse>> getServiceById(@PathVariable Integer id) {
        AcademicService service = academicServiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy dịch vụ với ID: " + id));
        return ResponseEntity.ok(ApiResponse.success(mapToResponse(service)));
    }

    @GetMapping("/by-category/{categoryId}")
    public ResponseEntity<ApiResponse<List<AcademicServiceResponse>>> getServicesByCategory(
            @PathVariable Integer categoryId) {
        List<AcademicServiceResponse> services = academicServiceRepository.findByCategoryId(categoryId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(services));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AcademicServiceResponse>> createService(
            @Valid @RequestBody CreateAcademicServiceDTO request) {

        log.info("Creating academic service: {}", request.getServiceCode());

        if (academicServiceRepository.existsByServiceCode(request.getServiceCode())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("DUPLICATE_CODE", "Mã dịch vụ đã tồn tại: " + request.getServiceCode()));
        }

        ServiceCategory category = serviceCategoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy danh mục với ID: " + request.getCategoryId()));

        AcademicService service = AcademicService.builder()
                .serviceCode(request.getServiceCode())
                .serviceName(request.getServiceName())
                .description(request.getDescription())
                .processingDays(request.getProcessingDays() != null ? request.getProcessingDays() : 15)
                .requiredDocuments(request.getRequiredDocuments())
                .formSchema(request.getFormSchema())
                .displayOrder(request.getDisplayOrder() != null ? request.getDisplayOrder() : 0)
                .serviceCategory(category)
                .isActive(true)
                .build();

        service = academicServiceRepository.save(service);
        log.info("Academic service created: {}", service.getServiceCode());

        // Reload để tránh LazyInitializationException (open-in-view=false)
        AcademicService saved = academicServiceRepository.findById(service.getId())
                .orElse(service);
        return ResponseEntity.ok(ApiResponse.success(mapToResponse(saved), "Tạo dịch vụ thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<AcademicServiceResponse>> updateService(
            @PathVariable Integer id,
            @RequestBody UpdateAcademicServiceDTO request) {

        AcademicService service = academicServiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy dịch vụ với ID: " + id));

        log.info("Updating academic service: {}", service.getServiceCode());

        if (request.getServiceName() != null)
            service.setServiceName(request.getServiceName());
        if (request.getDescription() != null)
            service.setDescription(request.getDescription());
        if (request.getCategoryId() != null) {
            ServiceCategory category = serviceCategoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy danh mục"));
            service.setServiceCategory(category);
        }
        if (request.getProcessingDays() != null)
            service.setProcessingDays(request.getProcessingDays());
        if (request.getRequiredDocuments() != null)
            service.setRequiredDocuments(request.getRequiredDocuments());
        if (request.getFormSchema() != null)
            service.setFormSchema(request.getFormSchema());
        if (request.getDisplayOrder() != null)
            service.setDisplayOrder(request.getDisplayOrder());
        if (request.getIsActive() != null)
            service.setIsActive(request.getIsActive());

        service = academicServiceRepository.save(service);
        log.info("Academic service updated: {}", service.getServiceCode());

        // Reload để tránh LazyInitializationException (open-in-view=false)
        AcademicService updated = academicServiceRepository.findById(service.getId())
                .orElse(service);
        return ResponseEntity.ok(ApiResponse.success(mapToResponse(updated), "Cập nhật thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteService(@PathVariable Integer id) {
        AcademicService service = academicServiceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy dịch vụ với ID: " + id));

        log.info("Deleting (deactivating) academic service: {}", service.getServiceCode());
        service.setIsActive(false);
        academicServiceRepository.save(service);

        return ResponseEntity.ok(ApiResponse.success(null, "Đã khóa dịch vụ"));
    }

    private AcademicServiceResponse mapToResponse(AcademicService service) {
        long requestCount = requestRepository.countByServiceId(service.getId());

        return AcademicServiceResponse.builder()
                .id(service.getId())
                .serviceCode(service.getServiceCode())
                .serviceName(service.getServiceName())
                .description(service.getDescription())
                .categoryId(service.getServiceCategory() != null ? service.getServiceCategory().getId() : null)
                .categoryName(service.getServiceCategory() != null ? service.getServiceCategory().getName() : null)
                .processingDays(service.getProcessingDays())
                .requiredDocuments(service.getRequiredDocuments())
                .formSchema(service.getFormSchema())
                .displayOrder(service.getDisplayOrder())
                .isActive(service.getIsActive())
                .createdAt(service.getCreatedAt())
                .requestCount((int) requestCount)
                .build();
    }
}











