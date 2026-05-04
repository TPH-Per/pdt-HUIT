package com.huit.pdt.domain.servicedesk.dto;

import java.time.LocalDateTime;

public record ServiceDeskDTO(
    Integer id,
    String deskCode,
    String deskName,
    Integer categoryId,
    Integer registrarId,
    String registrarName,
    Boolean isActive,
    LocalDateTime openedAt,
    LocalDateTime closedAt
) {}
