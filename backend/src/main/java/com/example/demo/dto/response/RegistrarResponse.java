package com.example.demo.dto.response;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegistrarResponse {
    private Integer id;
    private String registrarCode;
    private String fullName;
    private String email;
    private String phone;
    private Integer roleId;
    private String roleName;
    private String roleDisplayName;
    private Integer deskId;
    private String deskName;
    private Boolean isActive;
    private LocalDateTime createdAt;
}
