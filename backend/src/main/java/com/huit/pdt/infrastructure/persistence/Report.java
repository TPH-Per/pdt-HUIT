package com.huit.pdt.infrastructure.persistence;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "report")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Report {

    // Report type constants
    public static final int TYPE_FEEDBACK = 0;
    public static final int TYPE_COMPLAINT = 1;
    public static final int TYPE_PRAISE = 2;

    // Status constants
    public static final int STATUS_NEW = 0;
    public static final int STATUS_PROCESSING = 1;
    public static final int STATUS_RESOLVED = 2;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student; // FK to Student.studentId (MSSV)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "request_id")
    private Request request;

    @Column(name = "report_type", nullable = false)
    @Builder.Default
    private Integer reportType = TYPE_FEEDBACK;

    @Column(name = "title")
    private String title;

    @Column(name = "content", nullable = false)
    private String content;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "attachments", columnDefinition = "jsonb")
    private String attachments;

    @Column(name = "status")
    @Builder.Default
    private Integer status = STATUS_NEW;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}









