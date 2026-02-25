package com.example.demo.repository;

import com.example.demo.entity.ServiceDesk;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ServiceDeskRepository extends JpaRepository<ServiceDesk, Integer> {

    Optional<ServiceDesk> findByDeskCode(String deskCode);

    boolean existsByDeskCode(String deskCode);

    List<ServiceDesk> findByIsActiveTrueOrderByDeskCode();

    @Query("SELECT d FROM ServiceDesk d WHERE d.isActive = true ORDER BY d.deskCode")
    List<ServiceDesk> findAllActive();

    @Query("SELECT d FROM ServiceDesk d WHERE d.serviceCategory.id = :categoryId")
    List<ServiceDesk> findByCategoryId(Integer categoryId);
}
