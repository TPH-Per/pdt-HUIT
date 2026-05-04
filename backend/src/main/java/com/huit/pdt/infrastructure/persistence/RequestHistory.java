package com.huit.pdt.infrastructure.persistence;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Map;

@Entity
@Table(name = "request_history")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RequestHistory {

    // Action constants
    public static final String ACTION_CREATE = "CREATE";
    public static final String ACTION_CALL = "CALL";
    public static final String ACTION_REQUEST_DOCS = "REQUEST_DOCS";
    public static final String ACTION_SUBMIT_DOCS = "SUBMIT_DOCS";
    public static final String ACTION_COMPLETE = "COMPLETE";
    public static final String ACTION_CANCEL_NO_SHOW = "CANCEL_NO_SHOW";
    public static final String ACTION_CANCEL_SELF = "CANCEL_SELF";
    public static final String ACTION_CANCEL_REJECT = "CANCEL_REJECT";
    public static final String ACTION_UPDATE = "UPDATE";
    public static final String ACTION_RESCHEDULE = "RESCHEDULE";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "request_id", nullable = false)
    private Request request;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "desk_id")
    private ServiceDesk serviceDesk;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "registrar_id")
    private Registrar registrar;

    @Column(name = "phase_from")
    private Integer phaseFrom;

    @Column(name = "phase_to", nullable = false)
    private Integer phaseTo;

    @Column(name = "action", nullable = false)
    private String action;

    @Column(name = "content")
    private String content;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "form_data", columnDefinition = "jsonb")
    private Map<String, Object> formData;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "attachments", columnDefinition = "jsonb")
    private Map<String, Object> attachments;

    @Column(name = "appointment_date")
    private LocalDate appointmentDate;

    @Column(name = "expected_time")
    private LocalTime expectedTime;

    @Column(name = "queue_number")
    private Integer queueNumber;

    @Column(name = "queue_prefix")
    private String queuePrefix;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}









