package com.huit.pdt.infrastructure.persistence;

import com.huit.pdt.infrastructure.persistence.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface StudentRepository extends JpaRepository<Student, String> {

    Optional<Student> findByStudentId(String studentId);

    Optional<Student> findByPhone(String phone);

    @Query("SELECT s FROM Student s WHERE s.fullName LIKE %:name%")
    List<Student> findByFullNameContaining(String name);
}











