package com.example.demo.repository;

import com.example.demo.entity.Appointment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, Integer> {

    @Query("SELECT a.appointmentTime FROM Appointment a WHERE a.appointmentDate = :date AND a.status = 0")
    List<LocalTime> findBookedTimes(@Param("date") LocalDate date);

    @Query("SELECT a.appointmentTime FROM Appointment a " +
            "JOIN a.request r JOIN r.academicService s " +
            "WHERE a.appointmentDate = :date AND a.status = 0 " +
            "AND s.serviceCategory.id = :categoryId")
    List<LocalTime> findBookedTimesByCategory(@Param("date") LocalDate date, @Param("categoryId") Integer categoryId);

    @Query("SELECT a FROM Appointment a WHERE a.request.id = :requestId AND a.status = 0")
    List<Appointment> findActiveByRequestId(@Param("requestId") Integer requestId);

    @Query("SELECT COUNT(a) > 0 FROM Appointment a " +
            "JOIN a.request r " +
            "WHERE r.student.studentId = :studentId " +
            "AND a.appointmentDate = :date " +
            "AND a.appointmentTime = :time " +
            "AND a.status = 0")
    boolean existsByStudentAndDateTime(@Param("studentId") String studentId, @Param("date") LocalDate date,
            @Param("time") LocalTime time);
}
