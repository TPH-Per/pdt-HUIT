package com.huit.pdt.web.dto;

import lombok.*;
import java.time.LocalDateTime;

/**
 * AcademicService Response DTO - English fields
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AcademicServiceResponse {

    private Integer id;
    private String serviceCode;
    private String serviceName;
    private String description;
    private Integer categoryId;
    private String categoryName;
    private Integer processingDays;
    private String requiredDocuments;
    private String formSchema;
    private Integer displayOrder;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private Integer requestCount;
}










