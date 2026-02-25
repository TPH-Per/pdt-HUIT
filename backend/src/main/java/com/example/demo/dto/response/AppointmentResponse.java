package com.example.demo.dto.response;

import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Appointment Response DTO - English fields
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppointmentResponse {
    private Integer id;
    private String appointmentCode;
    private Integer queueNumber;
    private String queueDisplay;
    private String studentId;
    private String studentName;
    private String studentPhone;
    private String serviceName;
    private String serviceCode;
    private String deskName;
    private String deskCode;
    private LocalDate appointmentDate;
    private LocalTime expectedTime;
    private LocalDateTime calledAt;
    private LocalDateTime processingStartedAt;
    private LocalDateTime completedAt;
    private Integer status;
    private String statusText;
    private String registrarName;
    private String cancelReason;
}
