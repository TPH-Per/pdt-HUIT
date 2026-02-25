package com.example.demo.controller;

import com.example.demo.dto.response.ApiResponse;
import com.example.demo.entity.AcademicService;
import com.example.demo.repository.AcademicServiceRepository;
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
@RequestMapping("/api/public/services")
@RequiredArgsConstructor
public class PublicServiceController {

    private final AcademicServiceRepository academicServiceRepository;

    @GetMapping
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
}
