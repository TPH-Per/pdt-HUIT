package com.huit.pdt.web.dto;

import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RequestResponse {
    private Integer id;
    private String requestCode;

    // Service info
    private Integer serviceId;
    private String serviceCode;
    private String serviceName;

    // Student info
    private String studentId;
    private String studentName;
    private String studentPhone;

    // Phase
    private Integer currentPhase;
    private String phaseName;

    // Queue info
    private Integer queueNumber;
    private String queuePrefix;
    private String queueDisplay;
    private LocalDate appointmentDate;
    private LocalTime expectedTime;

    // Processing info
    private LocalDate deadline;
    private Integer priority;
    private String priorityName;

    // Cancellation
    private String cancelReason;
    private Integer cancelType;

    // Timestamps
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static String getPhaseName(Integer phase) {
        if (phase == null)
            return "Unknown";
        return switch (phase) {
            case 0 -> "Cancelled";
            case 1 -> "Queue";
            case 2 -> "Pending";
            case 3 -> "Processing";
            case 4 -> "Completed";
            case 5 -> "Received";
            default -> "Unknown";
        };
    }

    public static String getPriorityName(Integer priority) {
        if (priority == null)
            return "Normal";
        return switch (priority) {
            case 1 -> "Priority";
            case 2 -> "Urgent";
            default -> "Normal";
        };
    }
}










