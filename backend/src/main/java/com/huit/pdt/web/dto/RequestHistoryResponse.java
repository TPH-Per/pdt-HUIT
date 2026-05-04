package com.huit.pdt.web.dto;

import lombok.*;
import java.time.LocalDateTime;
import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RequestHistoryResponse {
    private Integer id;
    private Integer requestId;
    private String requestCode;

    // Desk info
    private Integer deskId;
    private String deskName;

    // Registrar info
    private Integer registrarId;
    private String registrarName;

    // Phase change
    private Integer phaseFrom;
    private String phaseFromName;
    private Integer phaseTo;
    private String phaseToName;

    // Action
    private String action;
    private String content;

    // Form data
    private Map<String, Object> formData;
    private Map<String, Object> attachments;

    private LocalDateTime createdAt;
}










