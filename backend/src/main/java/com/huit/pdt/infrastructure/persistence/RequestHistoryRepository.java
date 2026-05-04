package com.huit.pdt.infrastructure.persistence;

import com.huit.pdt.infrastructure.persistence.Request;
import com.huit.pdt.infrastructure.persistence.RequestHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Repository
public interface RequestHistoryRepository extends JpaRepository<RequestHistory, Integer> {

        @Query("SELECT h FROM RequestHistory h WHERE h.request.id = :requestId ORDER BY h.createdAt DESC")
        List<RequestHistory> findByRequestId(Integer requestId);

        @Query("SELECT h FROM RequestHistory h WHERE h.serviceDesk.id = :deskId ORDER BY h.createdAt DESC")
        List<RequestHistory> findByDeskId(Integer deskId);

        @Query("SELECT h FROM RequestHistory h WHERE h.registrar.id = :registrarId ORDER BY h.createdAt DESC")
        List<RequestHistory> findByRegistrarId(Integer registrarId);

        @Query("SELECT h FROM RequestHistory h WHERE h.request.id = :requestId AND h.action = :action ORDER BY h.createdAt DESC")
        List<RequestHistory> findByRequestIdAndAction(Integer requestId, String action);

        @Query("SELECT DISTINCT h.request FROM RequestHistory h " +
                        "WHERE h.appointmentDate = :date " +
                        "AND h.request.currentPhase = :phase " +
                        "ORDER BY h.request.queueNumber ASC")
        List<Request> findRequestsByAppointmentDateAndPhase(
                        @Param("date") LocalDate date,
                        @Param("phase") Integer phase);

        @Query("SELECT DISTINCT h.request FROM RequestHistory h " +
                        "WHERE h.appointmentDate = :date " +
                        "AND h.request.currentPhase IN :phases " +
                        "ORDER BY h.request.queueNumber ASC")
        List<Request> findRequestsByAppointmentDateAndPhases(
                        @Param("date") LocalDate date,
                        @Param("phases") List<Integer> phases);

        @Query("SELECT h.expectedTime FROM RequestHistory h WHERE h.appointmentDate = :date AND h.expectedTime IS NOT NULL AND h.request.currentPhase NOT IN (0, 4)")
        List<LocalTime> findBookedTimes(@Param("date") LocalDate date);

        @Query("SELECT DISTINCT h.request FROM RequestHistory h " +
                        "WHERE h.appointmentDate = :date " +
                        "ORDER BY h.request.queueNumber ASC")
        List<Request> findRequestsByAppointmentDate(@Param("date") LocalDate date);

        @Query("SELECT COUNT(DISTINCT h.request) FROM RequestHistory h " +
                        "WHERE h.appointmentDate = :date " +
                        "AND h.request.currentPhase = :phase")
        Long countByAppointmentDateAndPhase(
                        @Param("date") LocalDate date,
                        @Param("phase") Integer phase);

        @Query("SELECT h FROM RequestHistory h " +
                        "WHERE h.request.id = :requestId " +
                        "AND h.appointmentDate IS NOT NULL " +
                        "ORDER BY h.createdAt DESC")
        List<RequestHistory> findLatestAppointmentHistory(Integer requestId);

        @Query("SELECT h FROM RequestHistory h " +
                        "WHERE h.appointmentDate = :date " +
                        "AND h.phaseTo = :phase " +
                        "AND h.request.currentPhase = :phase " +
                        "AND h.id IN (SELECT MAX(h2.id) FROM RequestHistory h2 GROUP BY h2.request) " +
                        "ORDER BY h.expectedTime ASC, h.request.queueNumber ASC")
        List<RequestHistory> findActiveQueueHistories(@Param("date") LocalDate date, @Param("phase") Integer phase);
}











