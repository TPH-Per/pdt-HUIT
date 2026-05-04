package com.huit.pdt.domain.queue.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record CreateQueueTicketRequest(
    @NotNull(message = "Desk ID is required")
    @Positive(message = "Desk ID must be positive")
    Integer deskId,
    
    String studentId,
    
    Integer requestId
) {}
