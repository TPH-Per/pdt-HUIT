package com.huit.pdt.domain.appointment.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.time.LocalDate;
import java.time.LocalTime;

public record CreateAppointmentRequest(
    @NotNull(message = "Request ID is required")
    @Positive(message = "Request ID must be positive")
    Integer requestId,
    
    @NotNull(message = "Registrar ID is required")
    @Positive(message = "Registrar ID must be positive")
    Integer registrarId,
    
    @NotNull(message = "Appointment date is required")
    LocalDate appointmentDate,
    
    @NotNull(message = "Appointment time is required")
    LocalTime appointmentTime
) {}
