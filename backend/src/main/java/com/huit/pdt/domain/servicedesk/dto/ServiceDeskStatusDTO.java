package com.huit.pdt.domain.servicedesk.dto;

public record ServiceDeskStatusDTO(
    Integer id,
    String deskName,
    String deskCode,
    Boolean isActive,
    String registrarName,
    Integer waitingCount,
    Integer servingCount
) {}
