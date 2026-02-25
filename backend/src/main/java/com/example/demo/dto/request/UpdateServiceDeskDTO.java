package com.example.demo.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateServiceDeskDTO {

    @JsonAlias({ "tenQuay", "deskName" })
    private String deskName;

    @JsonAlias({ "viTri", "location" })
    private String location;

    @JsonAlias({ "chuyenMonId", "categoryId" })
    private Integer categoryId;

    @JsonAlias({ "ghiChu", "notes" })
    private String notes;

    @JsonAlias({ "trangThai", "isActive" })
    private Boolean isActive;
}
