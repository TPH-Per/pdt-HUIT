package com.huit.pdt.web.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateServiceCategoryDTO {

    @NotBlank(message = "Category name is required")
    @JsonAlias({ "tenChuyenMon", "name" })
    private String name;

    @JsonAlias({ "moTa", "description" })
    private String description;
}










