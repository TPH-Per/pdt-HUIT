package com.huit.pdt.domain.report.dto;

import java.time.LocalDate;

public record DailyStats(
    LocalDate date,
    Long totalActive,
    Long waiting,
    Long pending,
    Long processing,
    Long completed,
    Long cancelled
) {}
