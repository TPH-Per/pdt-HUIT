package com.huit.pdt.domain.appointment.dto;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;

public record AppointmentDTO(
    Integer id,
    Integer requestId,
    Integer registrarId,
    LocalDate appointmentDate,
    LocalTime appointmentTime,
    Integer status,
    LocalDateTime createdAt
) {}
