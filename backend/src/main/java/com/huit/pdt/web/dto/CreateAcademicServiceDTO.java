package com.huit.pdt.web.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateAcademicServiceDTO {

    @NotBlank(message = "Service code is required")
    @JsonAlias({ "maThuTuc", "serviceCode" })
    private String serviceCode;

    @NotBlank(message = "Service name is required")
    @JsonAlias({ "tenThuTuc", "serviceName" })
    private String serviceName;

    @JsonAlias({ "moTa", "description" })
    private String description;

    @NotNull(message = "Category ID is required")
    @JsonAlias({ "chuyenMonId", "categoryId" })
    private Integer categoryId;

    @JsonAlias({ "thoiGianXuLy", "processingDays" })
    private Integer processingDays;

    @JsonAlias({ "giayToYeuCau", "requiredDocuments" })
    private String requiredDocuments;

    @JsonAlias({ "formSchema" })
    private String formSchema;

    @JsonAlias({ "thuTu", "displayOrder" })
    private Integer displayOrder;
}










