package com.huit.pdt.infrastructure.persistence;

import com.huit.pdt.infrastructure.persistence.ServiceCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ServiceCategoryRepository extends JpaRepository<ServiceCategory, Integer> {

    Optional<ServiceCategory> findByName(String name);

    boolean existsByName(String name);

    List<ServiceCategory> findByIsActiveTrueOrderByName();

    @Query("SELECT COUNT(d) FROM ServiceDesk d WHERE d.serviceCategory.id = :categoryId")
    long countDesksByCategoryId(Integer categoryId);

    @Query("SELECT COUNT(s) FROM AcademicService s WHERE s.serviceCategory.id = :categoryId")
    long countServicesByCategoryId(Integer categoryId);
}











