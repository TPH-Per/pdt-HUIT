package com.example.demo.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateServiceDeskDTO {

    @NotBlank(message = "Desk code is required")
    @JsonAlias({ "maQuay", "deskCode" })
    private String deskCode;

    @NotBlank(message = "Desk name is required")
    @JsonAlias({ "tenQuay", "deskName" })
    private String deskName;

    @JsonAlias({ "viTri", "location" })
    private String location;

    @JsonAlias({ "chuyenMonId", "categoryId" })
    private Integer categoryId;

    @JsonAlias({ "ghiChu", "notes" })
    private String notes;
}
