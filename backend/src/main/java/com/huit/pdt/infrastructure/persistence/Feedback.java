package com.huit.pdt.infrastructure.persistence;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.LocalDateTime;
import java.util.Map;

@Entity
@Table(name = "student_feedback")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Feedback {

    // Type constants
    public static final int TYPE_SUGGESTION = 1;
    public static final int TYPE_COMPLAINT = 2;
    public static final int TYPE_COMPLIMENT = 3;

    // Status constants
    public static final int STATUS_PENDING = 0;
    public static final int STATUS_PROCESSING = 1;
    public static final int STATUS_RESOLVED = 2;
    public static final int STATUS_COMPLETED = 3;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "feedback_code", unique = true, nullable = false)
    private String feedbackCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", referencedColumnName = "student_id")
    private Student student;

    @Column(name = "feedback_type", nullable = false)
    private Integer type;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "content", columnDefinition = "TEXT")
    private String content;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "attachments", columnDefinition = "JSONB")
    private Map<String, Object> attachments;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "request_id")
    private Request request;

    @Column(name = "status", nullable = false)
    @Builder.Default
    private Integer status = STATUS_PENDING;

    @Column(name = "priority")
    @Builder.Default
    private Integer priority = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "registrar_id")
    private Registrar respondedBy;

    @Column(name = "internal_note", columnDefinition = "TEXT")
    private String internalNote;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "processed_at")
    private LocalDateTime processedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "rating")
    private Integer rating;

    @Column(name = "rating_feedback", columnDefinition = "TEXT")
    private String ratingFeedback;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (feedbackCode == null) {
            feedbackCode = "FB-" + System.currentTimeMillis();
        }
    }
}









