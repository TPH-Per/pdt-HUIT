package com.huit.pdt.domain.servicedesk.service;

import com.huit.pdt.domain.servicedesk.dto.ServiceDeskDTO;
import com.huit.pdt.domain.servicedesk.dto.ServiceDeskStatusDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ServiceDeskServiceImpl implements ServiceDeskService {

    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public Optional<ServiceDeskDTO> openDesk(Integer deskId, Integer registrarId) {
        ServiceDeskDTO dto = jdbc.queryForObject("""
            UPDATE service_desk
            SET is_active = TRUE, registrar_id = :registrarId, opened_at = NOW()
            WHERE id = :deskId
            RETURNING id, desk_code, desk_name, service_category_id, registrar_id, NULL as registrar_name, is_active, opened_at, closed_at
            """,
            Map.of("deskId", deskId, "registrarId", registrarId),
            new ServiceDeskRowMapper());
        return Optional.ofNullable(dto);
    }

    @Override
    public Optional<ServiceDeskDTO> closeDesk(Integer deskId, Integer registrarId) {
        jdbc.update("""
            UPDATE queue_tickets SET status = 'CANCELLED', notes = 'Desk closed'
            WHERE desk_id = :deskId AND status = 'WAITING'
              AND DATE(created_at) = CURRENT_DATE
            """, Map.of("deskId", deskId));
            
        ServiceDeskDTO dto = jdbc.queryForObject("""
            UPDATE service_desk
            SET is_active = FALSE, registrar_id = NULL, closed_at = NOW()
            WHERE id = :deskId
            RETURNING id, desk_code, desk_name, service_category_id, registrar_id, NULL as registrar_name, is_active, opened_at, closed_at
            """, Map.of("deskId", deskId), new ServiceDeskRowMapper());
        return Optional.ofNullable(dto);
    }

    @Override
    @Cacheable(value = "service-desks", key = "'all-active'")
    public List<ServiceDeskStatusDTO> getActiveDesks() {
        return jdbc.query("""
            SELECT sd.id, sd.desk_name, sd.desk_code, sd.is_active,
                   reg.full_name AS registrar_name,
                   COUNT(qt.id) FILTER (WHERE qt.status = 'WAITING')             AS waiting_count,
                   COUNT(qt.id) FILTER (WHERE qt.status IN ('CALLING','SERVING')) AS serving_count
            FROM service_desk sd
            LEFT JOIN registrar reg ON reg.id = sd.registrar_id
            LEFT JOIN queue_tickets qt ON qt.desk_id = sd.id
                AND DATE(qt.created_at) = CURRENT_DATE
            GROUP BY sd.id, sd.desk_name, sd.desk_code, sd.is_active, reg.full_name
            ORDER BY sd.desk_code
            """, Map.of(), new ServiceDeskStatusRowMapper());
    }

    @Override
    public Optional<ServiceDeskDTO> getDeskById(Integer deskId) {
        List<ServiceDeskDTO> list = jdbc.query("""
            SELECT id, desk_code, desk_name, service_category_id, registrar_id, NULL as registrar_name, is_active, opened_at, closed_at
            FROM service_desk WHERE id = :id
            """, Map.of("id", deskId), new ServiceDeskRowMapper());
        return list.isEmpty() ? Optional.empty() : Optional.of(list.get(0));
    }

    @Override
    public List<ServiceDeskDTO> getDesksByCategory(Integer categoryId) {
        return jdbc.query("""
            SELECT id, desk_code, desk_name, service_category_id, registrar_id, NULL as registrar_name, is_active, opened_at, closed_at
            FROM service_desk WHERE service_category_id = :categoryId
            """, Map.of("categoryId", categoryId), new ServiceDeskRowMapper());
    }

    public static class ServiceDeskRowMapper implements RowMapper<ServiceDeskDTO> {
        @Override
        public ServiceDeskDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
            return new ServiceDeskDTO(
                rs.getInt("id"),
                rs.getString("desk_code"),
                rs.getString("desk_name"),
                rs.getInt("service_category_id"),
                rs.getInt("registrar_id") == 0 ? null : rs.getInt("registrar_id"),
                rs.getString("registrar_name"),
                rs.getBoolean("is_active"),
                rs.getTimestamp("opened_at") != null ? rs.getTimestamp("opened_at").toLocalDateTime() : null,
                rs.getTimestamp("closed_at") != null ? rs.getTimestamp("closed_at").toLocalDateTime() : null
            );
        }
    }

    public static class ServiceDeskStatusRowMapper implements RowMapper<ServiceDeskStatusDTO> {
        @Override
        public ServiceDeskStatusDTO mapRow(ResultSet rs, int rowNum) throws SQLException {
            return new ServiceDeskStatusDTO(
                rs.getInt("id"),
                rs.getString("desk_name"),
                rs.getString("desk_code"),
                rs.getBoolean("is_active"),
                rs.getString("registrar_name"),
                rs.getInt("waiting_count"),
                rs.getInt("serving_count")
            );
        }
    }
}
