package com.huit.pdt.infrastructure.persistence;

import com.huit.pdt.infrastructure.persistence.Registrar;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RegistrarRepository extends JpaRepository<Registrar, Integer> {

    Optional<Registrar> findByRegistrarCode(String registrarCode);

    boolean existsByRegistrarCode(String registrarCode);

    boolean existsByEmail(String email);

    @Query("SELECT r FROM Registrar r WHERE r.isActive = true")
    List<Registrar> findAllActive();

    @Query("SELECT r FROM Registrar r WHERE r.serviceDesk.id = :deskId")
    List<Registrar> findByDeskId(@Param("deskId") Integer deskId);

    @Query("SELECT r FROM Registrar r WHERE r.role.roleName = :roleName")
    List<Registrar> findByRoleName(@Param("roleName") String roleName);

    @Query("SELECT COUNT(r) FROM Registrar r WHERE r.serviceDesk.id = :deskId")
    long countByDeskId(@Param("deskId") Integer deskId);
}











