package com.huit.pdt.web.dto;

import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudentResponse {
    private String studentId; // MSSV
    private String fullName;
    private LocalDate dateOfBirth;
    private String gender;
    private String major;
    private String phone;
    private String email;
    private LocalDateTime createdAt;
}










