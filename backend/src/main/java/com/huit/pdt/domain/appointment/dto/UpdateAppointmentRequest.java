package com.huit.pdt.domain.appointment.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.time.LocalTime;

public record UpdateAppointmentRequest(
    LocalDate appointmentDate,
    LocalTime appointmentTime,
    Integer status
) {}
