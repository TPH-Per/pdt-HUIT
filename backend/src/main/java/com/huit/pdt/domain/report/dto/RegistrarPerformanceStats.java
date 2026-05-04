package com.huit.pdt.domain.report.dto;

public record RegistrarPerformanceStats(
    Integer registrarId,
    String registrarName,
    Long requestsProcessed,
    Double avgProcessingMinutes,
    Long completedRequests
) {}
