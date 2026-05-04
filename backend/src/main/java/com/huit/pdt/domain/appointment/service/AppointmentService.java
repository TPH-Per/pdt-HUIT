package com.huit.pdt.domain.appointment.service;

import com.huit.pdt.domain.appointment.dto.AppointmentDTO;
import com.huit.pdt.domain.appointment.dto.CreateAppointmentRequest;
import com.huit.pdt.domain.appointment.dto.UpdateAppointmentRequest;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface AppointmentService {
    Optional<AppointmentDTO> createAppointment(CreateAppointmentRequest request);
    Optional<AppointmentDTO> updateAppointment(Integer id, UpdateAppointmentRequest request);
    Optional<AppointmentDTO> cancelAppointment(Integer id, String reason);
    Optional<AppointmentDTO> getAppointmentById(Integer id);
    List<AppointmentDTO> getAppointmentsByDate(LocalDate date);
    List<AppointmentDTO> getAppointmentsByStudent(String studentId);
    List<AppointmentDTO> getAvailableSlots(LocalDate date, Integer registrarId);
}
