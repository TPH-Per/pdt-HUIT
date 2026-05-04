package com.huit.pdt.web.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateAcademicServiceDTO {

    @JsonAlias({ "tenThuTuc", "serviceName" })
    private String serviceName;

    @JsonAlias({ "moTa", "description" })
    private String description;

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

    @JsonAlias({ "trangThai", "isActive" })
    private Boolean isActive;
}










