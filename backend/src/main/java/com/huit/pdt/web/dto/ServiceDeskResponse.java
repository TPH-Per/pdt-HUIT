package com.huit.pdt.web.dto;

import lombok.*;
import java.time.LocalDateTime;

/**
 * ServiceDesk Response DTO - English fields
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ServiceDeskResponse {

    private Integer id;
    private String deskCode;
    private String deskName;
    private String location;
    private Integer categoryId;
    private String categoryName;
    private Boolean isActive;
    private String notes;
    private LocalDateTime createdAt;
    private Integer staffCount;
}










