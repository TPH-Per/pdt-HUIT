package com.huit.pdt.infrastructure.persistence;

import com.huit.pdt.infrastructure.persistence.Request;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface RequestRepository extends JpaRepository<Request, Integer> {

    Optional<Request> findByRequestCode(String requestCode);

    List<Request> findByCurrentPhaseOrderByQueueNumberAsc(Integer phase);

    @Query("SELECT r FROM Request r WHERE r.student.studentId = :studentId ORDER BY r.createdAt DESC")
    List<Request> findByStudentId(String studentId);

    @Query("SELECT r FROM Request r WHERE r.academicService.id = :serviceId ORDER BY r.createdAt DESC")
    List<Request> findByServiceId(Integer serviceId);

    @Query("SELECT COUNT(r) FROM Request r WHERE r.currentPhase = :phase")
    Long countByPhase(Integer phase);

    @Query("SELECT COUNT(r) FROM Request r WHERE r.academicService.id = :serviceId")
    long countByServiceId(Integer serviceId);

    @Query("SELECT COALESCE(MAX(r.queueNumber), 0) FROM Request r WHERE r.queuePrefix = :prefix")
    Integer findMaxQueueNumber(String prefix);

    @Query("SELECT r FROM Request r WHERE r.student.studentId = :studentId ORDER BY r.createdAt DESC")
    List<Request> findByStudentStudentId(String studentId);

    @Query("SELECT COUNT(r) FROM Request r WHERE CAST(r.createdAt AS LocalDate) = :date")
    int countByCreatedAtDate(java.time.LocalDate date);

    @Query("SELECT r FROM Request r WHERE CONCAT(r.queuePrefix, '-', LPAD(CAST(r.queueNumber AS string), 3, '0')) = :display")
    Optional<Request> findByQueueDisplay(String display);
}











