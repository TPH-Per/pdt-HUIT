package com.huit.pdt.web.dto;

import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateServiceRequestDTO {

    @NotNull(message = "Service ID is required")
    private Integer serviceId;

    // Student info - can be existing or new
    @Size(min = 10, max = 10, message = "Student ID (MSSV) must be exactly 10 characters")
    private String studentId;

    // If new student, provide these:
    private String studentName;
    private LocalDate studentDateOfBirth;
    private String studentGender;
    private String studentMajor;
    private String studentPhone;
    private String studentEmail;

    // Queue info
    private LocalDate appointmentDate;
    private LocalTime expectedTime;

    // Priority
    private Integer priority = 0;
}










