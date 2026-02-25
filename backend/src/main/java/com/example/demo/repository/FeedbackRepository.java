package com.example.demo.repository;

import com.example.demo.entity.Feedback;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface FeedbackRepository extends JpaRepository<Feedback, Integer> {

    @Query("SELECT f FROM Feedback f WHERE f.student.studentId = :studentId ORDER BY f.createdAt DESC")
    List<Feedback> findByStudentStudentId(String studentId);

    List<Feedback> findByStatus(Integer status);

    @Query("SELECT f FROM Feedback f ORDER BY f.createdAt DESC")
    List<Feedback> findAllOrderByCreatedAtDesc();
}
