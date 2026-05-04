package com.huit.pdt.web.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for queue status update request
 * 
 * Used when: Staff clicks "Complete", "Cancel", "Call again"...
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QueueStatusRequest {

    /**
     * New phase to update
     * 
     * Valid values:
     * - 1: QUEUE (waiting)
     * - 2: PENDING (missing documents)
     * - 3: PROCESSING
     * - 4: COMPLETED
     * - 0: CANCELLED
     */
    @NotNull(message = "Phase is required")
    private Integer phase;

    /**
     * Cancellation reason / notes
     * 
     * Required when: phase = 0 (Cancelled)
     * Optional when: phase = 4 (Completed) - additional notes
     */
    private String reason;

    /**
     * Additional notes (optional)
     * 
     * e.g., "Customer forgot documents", "Need additional documents"
     */
    private String notes;
}










