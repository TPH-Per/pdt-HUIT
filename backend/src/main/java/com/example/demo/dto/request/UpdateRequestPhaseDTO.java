package com.example.demo.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateRequestPhaseDTO {

    @NotNull(message = "Request ID is required")
    private Integer requestId;

    @NotNull(message = "Desk ID is required")
    private Integer deskId;

    @NotBlank(message = "Action is required")
    private String action; // CALL, REQUEST_DOCS, SUBMIT_DOCS, COMPLETE, CANCEL_*

    private String content; // Notes/reason

    private Map<String, Object> formData;

    private Map<String, Object> attachments;
}
