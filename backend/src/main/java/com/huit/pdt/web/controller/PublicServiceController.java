package com.huit.pdt.web.controller;

import com.huit.pdt.web.dto.ApiResponse;
import com.huit.pdt.infrastructure.persistence.AcademicService;
import com.huit.pdt.infrastructure.persistence.ServiceCategory;
import com.huit.pdt.infrastructure.persistence.AcademicServiceRepository;
import com.huit.pdt.infrastructure.persistence.ServiceCategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

/**
 * Public Academic Service Controller
 * API công khai để lấy danh sách dịch vụ học vụ (không cần auth)
 */
@RestController
@RequestMapping("/api/public")
@RequiredArgsConstructor
public class PublicServiceController {

    private final AcademicServiceRepository academicServiceRepository;
    private final ServiceCategoryRepository serviceCategoryRepository;

    @GetMapping("/services")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getAllActive() {
        List<AcademicService> services = academicServiceRepository.findAllActive();

        List<Map<String, Object>> result = services.stream().map(p -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", p.getId());
            map.put("serviceCode", p.getServiceCode());
            map.put("serviceName", p.getServiceName());
            map.put("description", p.getDescription());
            map.put("processingDays", p.getProcessingDays());
            return map;
        }).toList();

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @GetMapping("/service-categories")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getPublicServiceCategories() {
        List<ServiceCategory> categories = serviceCategoryRepository.findByIsActiveTrueOrderByName();

        List<Map<String, Object>> result = categories.stream().map(c -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", c.getId());
            map.put("name", c.getName());
            map.put("description", c.getDescription());
            return map;
        }).toList();

        return ResponseEntity.ok(ApiResponse.success(result));
    }
}











