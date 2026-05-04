package com.huit.pdt.domain.appointment.service;

import com.huit.pdt.domain.appointment.dto.AppointmentDTO;
import com.huit.pdt.domain.appointment.dto.CreateAppointmentRequest;
import com.huit.pdt.domain.appointment.dto.UpdateAppointmentRequest;
import com.huit.pdt.infrastructure.persistence.Appointment;
import com.huit.pdt.infrastructure.persistence.AppointmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class AppointmentServiceImpl implements AppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public Optional<AppointmentDTO> createAppointment(CreateAppointmentRequest request) {
        String checkSql = "SELECT COUNT(*) FROM appointment WHERE registrar_id = :registrarId AND appointment_date = :appointmentDate AND appointment_time = :appointmentTime AND status != 2 FOR UPDATE";
        Integer count = jdbc.queryForObject(checkSql, Map.of("registrarId", request.registrarId(), "appointmentDate", request.appointmentDate(), "appointmentTime", request.appointmentTime()), Integer.class);

        if (count != null && count > 0) {
            log.warn("Slot already booked for registrar {} at {} {}", request.registrarId(), request.appointmentDate(), request.appointmentTime());
            return Optional.empty();
        }

        Appointment appointment = Appointment.builder().request(null).registrar(null).appointmentDate(request.appointmentDate()).appointmentTime(request.appointmentTime()).status(Appointment.STATUS_SCHEDULED).build();
        Appointment saved = appointmentRepository.save(appointment);
        log.info("Created appointment {}", saved.getId());
        return Optional.of(mapToDTO(saved));
    }

    @Override
    public Optional<AppointmentDTO> updateAppointment(Integer id, UpdateAppointmentRequest request) {
        String sql = "UPDATE appointment SET appointment_date = COALESCE(:appointmentDate, appointment_date), appointment_time = COALESCE(:appointmentTime, appointment_time), status = COALESCE(:status, status) WHERE id = :id RETURNING id, request_id, registrar_id, appointment_date, appointment_time, status, created_at";
        List<AppointmentDTO> result = jdbc.query(sql, Map.of("id", id, "appointmentDate", request.appointmentDate(), "appointmentTime", request.appointmentTime(), "status", request.status()), (rs, rowNum) -> new AppointmentDTO(rs.getInt("id"), rs.getObject("request_id", Integer.class), rs.getObject("registrar_id", Integer.class), rs.getObject("appointment_date", LocalDate.class), rs.getObject("appointment_time", LocalTime.class), rs.getInt("status"), rs.getTimestamp("created_at").toLocalDateTime()));
        if (!result.isEmpty()) {
            log.info("Updated appointment {}", id);
            return Optional.of(result.get(0));
        }
        return Optional.empty();
    }

    @Override
    public Optional<AppointmentDTO> cancelAppointment(Integer id, String reason) {
        String sql = "UPDATE appointment SET status = 2 WHERE id = :id RETURNING id, request_id, registrar_id, appointment_date, appointment_time, status, created_at";
        List<AppointmentDTO> result = jdbc.query(sql, Map.of("id", id), (rs, rowNum) -> new AppointmentDTO(rs.getInt("id"), rs.getObject("request_id", Integer.class), rs.getObject("registrar_id", Integer.class), rs.getObject("appointment_date", LocalDate.class), rs.getObject("appointment_time", LocalTime.class), rs.getInt("status"), rs.getTimestamp("created_at").toLocalDateTime()));
        if (!result.isEmpty()) {
            log.info("Cancelled appointment {} with reason: {}", id, reason);
            return Optional.of(result.get(0));
        }
        return Optional.empty();
    }

    @Override
    public Optional<AppointmentDTO> getAppointmentById(Integer id) {
        return appointmentRepository.findById(id).map(this::mapToDTO);
    }

    @Override
    public List<AppointmentDTO> getAppointmentsByDate(LocalDate date) {
        return appointmentRepository.findByAppointmentDate(date).stream().map(this::mapToDTO).toList();
    }

    @Override
    public List<AppointmentDTO> getAppointmentsByStudent(String studentId) {
        return appointmentRepository.findByRequest_Student_StudentId(studentId).stream().map(this::mapToDTO).toList();
    }

    @Override
    public List<AppointmentDTO> getAvailableSlots(LocalDate date, Integer registrarId) {
        String sql = "SELECT DISTINCT appointment_time FROM appointment WHERE registrar_id = :registrarId AND appointment_date = :appointmentDate AND status != 2 ORDER BY appointment_time";
        List<LocalTime> bookedTimes = jdbc.query(sql, Map.of("registrarId", registrarId, "appointmentDate", date), (rs, rowNum) -> rs.getObject("appointment_time", LocalTime.class));
        return bookedTimes.stream().map(time -> new AppointmentDTO(null, null, registrarId, date, time, null, null)).toList();
    }

    private AppointmentDTO mapToDTO(Appointment appointment) {
        return new AppointmentDTO(appointment.getId(), appointment.getRequest() != null ? appointment.getRequest().getId() : null, appointment.getRegistrar() != null ? appointment.getRegistrar().getId() : null, appointment.getAppointmentDate(), appointment.getAppointmentTime(), appointment.getStatus(), appointment.getCreatedAt());
    }
}
