package com.example.demo.repository;

import com.example.demo.entity.Reply;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ReplyRepository extends JpaRepository<Reply, Integer> {

    @Query("SELECT r FROM Reply r WHERE r.report.id = :reportId ORDER BY r.createdAt")
    List<Reply> findByReportId(Integer reportId);

    @Query("SELECT r FROM Reply r WHERE r.registrar.id = :registrarId ORDER BY r.createdAt DESC")
    List<Reply> findByRegistrarId(Integer registrarId);
}
