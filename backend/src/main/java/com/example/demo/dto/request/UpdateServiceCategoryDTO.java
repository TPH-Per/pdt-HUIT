package com.example.demo.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateServiceCategoryDTO {

    @JsonAlias({ "tenChuyenMon", "name" })
    private String name;

    @JsonAlias({ "moTa", "description" })
    private String description;

    @JsonAlias({ "trangThai", "isActive" })
    private Boolean isActive;
}
