package com.huit.pdt.web.dto;

import lombok.*;
import java.time.LocalDateTime;

/**
 * ServiceCategory Response DTO - English fields
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ServiceCategoryResponse {

    private Integer id;
    private String name;
    private String description;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private Integer deskCount;
    private Integer serviceCount;
}










