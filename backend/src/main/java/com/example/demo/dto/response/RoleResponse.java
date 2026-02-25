package com.example.demo.dto.response;

import lombok.*;

/**
 * Role Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoleResponse {
    private Integer id;
    private String roleName;
    private String displayName;
    private String description;
}
