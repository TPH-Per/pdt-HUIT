package com.huit.pdt.domain.report.dto;

public record ServiceUsageStats(
    Integer categoryId,
    String categoryName,
    Long requestCount,
    Double avgProcessingMinutes
) {}
