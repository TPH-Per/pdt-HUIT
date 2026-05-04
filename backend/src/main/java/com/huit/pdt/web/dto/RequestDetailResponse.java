package com.huit.pdt.web.dto;

import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Request Detail Response DTO - English fields
 * Used for detailed view of a service request
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RequestDetailResponse {
    private Integer id;
    private String requestCode;
    private String studentId;
    private String studentName;
    private String studentPhone;
    private String studentEmail;
    private String studentMajor;
    private String serviceName;
    private String serviceCode;
    private String deskName;
    private Integer currentPhase;
    private String phaseText;
    private Integer priority;
    private LocalDateTime submittedAt;
    private LocalDate deadline;
    private LocalDateTime completedAt;
    private String source;
    private String appointmentCode;
    private Integer categoryId;
    private Integer processingDays;
    private Map<String, Object> formData;
    private List<Map<String, Object>> attachments;
    private String notes;
    private List<HistoryDto> history;

    // For dashboard stats
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DashboardData {
        private Integer totalRequests;
        private Integer pending;
        private Integer processing;
        private Integer completed;
        private Integer overdue;
    }

    @Data
    @Builder
    public static class HistoryDto {
        private String registrarName;
        private String action;
        private String previousPhase;
        private String newPhase;
        private String content;
        private LocalDateTime timestamp;
    }

    // Phase text helper
    public static String getPhaseText(Integer phase) {
        if (phase == null)
            return "---";
        return switch (phase) {
            case 0 -> "Đã hủy";
            case 1 -> "Chờ gọi số";
            case 2 -> "Đang tiếp nhận";
            case 3 -> "Chờ gọi số";
            case 4 -> "Đã hoàn thành";
            case 5 -> "Đã tiếp nhận";
            case 6 -> "Bổ sung";
            default -> "Không xác định";
        };
    }
}










