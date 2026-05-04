package com.huit.pdt.domain.queue.dto;

import java.time.LocalDateTime;

public record QueueTicketDTO(
    Long id,
    Integer ticketNumber,
    String ticketPrefix,
    String studentId,
    Integer deskId,
    Integer registrarId,
    Integer requestId,
    String status,
    LocalDateTime createdAt,
    LocalDateTime calledAt,
    LocalDateTime servedAt,
    LocalDateTime completedAt,
    String notes
) {}
