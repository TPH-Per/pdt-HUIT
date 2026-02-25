package com.example.demo.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request to change application status/phase
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChangeStatusRequest {

    /**
     * New phase
     * 0: CANCELLED
     * 1: QUEUE (waiting)
     * 2: PENDING (missing documents)
     * 3: PROCESSING
     * 4: COMPLETED
     */
    @NotNull(message = "New phase is required")
    private Integer newPhase;

    // Reason / Note for this status change
    private String content; // e.g., "Missing household registration", "Approved"

    private String notes;
}
