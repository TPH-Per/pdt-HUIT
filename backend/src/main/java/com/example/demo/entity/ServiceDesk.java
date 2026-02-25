package com.example.demo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "service_desk")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ServiceDesk {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "desk_code", unique = true, nullable = false)
    private String deskCode;

    @Column(name = "desk_name", nullable = false)
    private String deskName;

    @Column(name = "location")
    private String location;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "service_category_id")
    private ServiceCategory serviceCategory;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "notes")
    private String notes;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
