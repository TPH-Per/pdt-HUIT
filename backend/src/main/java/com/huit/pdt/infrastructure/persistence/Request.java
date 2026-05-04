package com.huit.pdt.infrastructure.persistence;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "request")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Request {

    // Phase constants
    public static final int PHASE_CANCELLED = 0;
    public static final int PHASE_QUEUE = 1;
    public static final int PHASE_PENDING = 2;
    public static final int PHASE_PROCESSING = 3;
    public static final int PHASE_COMPLETED = 4;
    public static final int PHASE_RECEIVED = 5;
    public static final int PHASE_SUPPLEMENT = 6;

    // Priority constants
    public static final int PRIORITY_NORMAL = 0;
    public static final int PRIORITY_HIGH = 1;
    public static final int PRIORITY_URGENT = 2;

    // Cancel type constants
    public static final int CANCEL_NO_SHOW = 0;
    public static final int CANCEL_SELF = 1;
    public static final int CANCEL_REJECTED = 2;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "request_code", unique = true, nullable = false)
    private String requestCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "service_id", nullable = false)
    private AcademicService academicService;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student; // FK to Student.studentId (MSSV)

    @Column(name = "current_phase", nullable = false)
    @Builder.Default
    private Integer currentPhase = PHASE_QUEUE;

    @Column(name = "queue_number")
    private Integer queueNumber;

    @Column(name = "queue_prefix")
    private String queuePrefix;

    @Column(name = "deadline")
    private LocalDate deadline;

    @Column(name = "priority")
    @Builder.Default
    private Integer priority = PRIORITY_NORMAL;

    @Column(name = "cancel_reason")
    private String cancelReason;

    @Column(name = "cancel_type")
    private Integer cancelType;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // Helper methods
    public String getQueueDisplay() {
        if (queuePrefix != null && queueNumber != null) {
            return queuePrefix + String.format("%03d", queueNumber);
        }
        return null;
    }
}









