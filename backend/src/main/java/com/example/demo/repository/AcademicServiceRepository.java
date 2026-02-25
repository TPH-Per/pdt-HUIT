package com.example.demo.repository;

import com.example.demo.entity.AcademicService;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface AcademicServiceRepository extends JpaRepository<AcademicService, Integer> {

    Optional<AcademicService> findByServiceCode(String serviceCode);

    boolean existsByServiceCode(String serviceCode);

    List<AcademicService> findByIsActiveTrueOrderByDisplayOrder();

    @Query("SELECT s FROM AcademicService s WHERE s.isActive = true ORDER BY s.displayOrder")
    List<AcademicService> findAllActive();

    @Query("SELECT s FROM AcademicService s WHERE s.serviceCategory.id = :categoryId")
    List<AcademicService> findByCategoryId(Integer categoryId);

    @Query("SELECT s FROM AcademicService s WHERE s.serviceCategory.id = :categoryId AND s.isActive = :isActive ORDER BY s.displayOrder")
    List<AcademicService> findByCategoryIdAndIsActive(Integer categoryId, Boolean isActive);
}
