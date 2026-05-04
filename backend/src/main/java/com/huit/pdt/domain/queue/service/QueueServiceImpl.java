package com.huit.pdt.domain.queue.service;

import com.huit.pdt.domain.queue.dto.QueueTicketDTO;
import com.huit.pdt.domain.queue.dto.CreateQueueTicketRequest;
import com.huit.pdt.domain.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class QueueServiceImpl implements QueueService {

    private final NamedParameterJdbcTemplate jdbc;
    private final SimpMessagingTemplate ws;
    private final NotificationService notificationService;

    @Override
    public Optional<QueueTicketDTO> callNextTicket(Integer deskId, Integer registrarId) {
        String sql = "UPDATE queue_tickets SET status = 'CALLING', called_at = NOW(), registrar_id = :registrarId WHERE id = (SELECT id FROM queue_tickets WHERE desk_id = :deskId AND status = 'WAITING' AND DATE(created_at) = CURRENT_DATE ORDER BY ticket_number ASC LIMIT 1 FOR UPDATE SKIP LOCKED) RETURNING id, ticket_number, ticket_prefix, student_id, desk_id, registrar_id, request_id, status, created_at, called_at, served_at, completed_at, notes";

        List<QueueTicketDTO> result = jdbc.query(sql, Map.of("deskId", deskId, "registrarId", registrarId), this::mapRowToTicketDTO);

        if (!result.isEmpty()) {
            QueueTicketDTO ticket = result.get(0);
            ws.convertAndSend("/topic/queue/" + deskId, ticket);
            if (ticket.studentId() != null) {
                ws.convertAndSendToUser(ticket.studentId(), "/queue/your-turn", ticket);
                notificationService.createAndPush(ticket.studentId(), "QUEUE_CALLED", "Đến lượt của bạn!", "Số thứ tự: " + ticket.ticketPrefix() + ticket.ticketNumber(), ticket.id(), "QUEUE");
            }
            log.info("Called next ticket {} at desk {}", ticket.ticketNumber(), deskId);
            return Optional.of(ticket);
        }

        log.debug("No waiting tickets at desk {}", deskId);
        return Optional.empty();
    }

    @Override
    public Optional<QueueTicketDTO> createTicket(CreateQueueTicketRequest request) {
        String sql = "INSERT INTO queue_tickets (ticket_number, ticket_prefix, student_id, desk_id, request_id, status) VALUES (COALESCE((SELECT MAX(ticket_number) FROM queue_tickets WHERE desk_id = :deskId AND DATE(created_at) = CURRENT_DATE), 0) + 1, 'A', :studentId, :deskId, :requestId, 'WAITING') RETURNING id, ticket_number, ticket_prefix, student_id, desk_id, registrar_id, request_id, status, created_at, called_at, served_at, completed_at, notes";

        MapSqlParameterSource params = new MapSqlParameterSource().addValue("deskId", request.deskId()).addValue("studentId", request.studentId()).addValue("requestId", request.requestId());

        List<QueueTicketDTO> result = jdbc.query(sql, params, this::mapRowToTicketDTO);

        if (!result.isEmpty()) {
            QueueTicketDTO ticket = result.get(0);
            ws.convertAndSend("/topic/queue/" + request.deskId(), ticket);
            log.info("Created ticket {} at desk {}", ticket.ticketNumber(), request.deskId());
            return Optional.of(ticket);
        }

        return Optional.empty();
    }

    @Override
    public Optional<QueueTicketDTO> updateTicketStatus(Long ticketId, String status, Integer registrarId) {
        String sql = "UPDATE queue_tickets SET status = :status, registrar_id = :registrarId, served_at = CASE WHEN :status = 'SERVING' THEN NOW() ELSE served_at END, completed_at = CASE WHEN :status = 'COMPLETED' THEN NOW() ELSE completed_at END WHERE id = :ticketId RETURNING id, ticket_number, ticket_prefix, student_id, desk_id, registrar_id, request_id, status, created_at, called_at, served_at, completed_at, notes";

        List<QueueTicketDTO> result = jdbc.query(sql, Map.of("ticketId", ticketId, "status", status, "registrarId", registrarId), this::mapRowToTicketDTO);

        if (!result.isEmpty()) {
            QueueTicketDTO ticket = result.get(0);
            ws.convertAndSend("/topic/queue/" + ticket.deskId(), ticket);
            log.info("Updated ticket {} to status {}", ticketId, status);
            return Optional.of(ticket);
        }

        return Optional.empty();
    }

    @Override
    public List<QueueTicketDTO> getActiveTickets(Integer deskId) {
        String sql = "SELECT id, ticket_number, ticket_prefix, student_id, desk_id, registrar_id, request_id, status, created_at, called_at, served_at, completed_at, notes FROM queue_tickets WHERE desk_id = :deskId AND status IN ('WAITING', 'CALLING', 'SERVING') AND DATE(created_at) = CURRENT_DATE ORDER BY ticket_number ASC";
        return jdbc.query(sql, Map.of("deskId", deskId), this::mapRowToTicketDTO);
    }

    @Override
    public Optional<QueueTicketDTO> getTicketById(Long ticketId) {
        String sql = "SELECT id, ticket_number, ticket_prefix, student_id, desk_id, registrar_id, request_id, status, created_at, called_at, served_at, completed_at, notes FROM queue_tickets WHERE id = :ticketId";
        List<QueueTicketDTO> result = jdbc.query(sql, Map.of("ticketId", ticketId), this::mapRowToTicketDTO);
        return result.isEmpty() ? Optional.empty() : Optional.of(result.get(0));
    }

    @Override
    public void cancelTicket(Long ticketId, String reason) {
        String sql = "UPDATE queue_tickets SET status = 'CANCELLED', notes = COALESCE(:reason, 'Cancelled'), completed_at = NOW() WHERE id = :ticketId";
        jdbc.update(sql, Map.of("ticketId", ticketId, "reason", reason));
        log.info("Cancelled ticket {} with reason: {}", ticketId, reason);
    }

    private QueueTicketDTO mapRowToTicketDTO(ResultSet rs, int rowNum) throws SQLException {
        return new QueueTicketDTO(rs.getLong("id"), rs.getInt("ticket_number"), rs.getString("ticket_prefix"), rs.getString("student_id"), rs.getInt("desk_id"), rs.getObject("registrar_id", Integer.class), rs.getObject("request_id", Integer.class), rs.getString("status"), rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toLocalDateTime() : null, rs.getTimestamp("called_at") != null ? rs.getTimestamp("called_at").toLocalDateTime() : null, rs.getTimestamp("served_at") != null ? rs.getTimestamp("served_at").toLocalDateTime() : null, rs.getTimestamp("completed_at") != null ? rs.getTimestamp("completed_at").toLocalDateTime() : null, rs.getString("notes"));
    }
}
