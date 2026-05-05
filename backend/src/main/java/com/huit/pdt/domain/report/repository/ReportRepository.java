package com.huit.pdt.domain.report.repository;

import com.huit.pdt.domain.report.dto.ServiceUsageStats;
import com.huit.pdt.domain.report.dto.RegistrarPerformanceStats;
import com.huit.pdt.domain.report.dto.DailyStats;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Repository("jdbcReportRepository")
public class ReportRepository {

    private final NamedParameterJdbcTemplate jdbc;

    public ReportRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<ServiceUsageStats> getServiceUsageStats(LocalDate startDate, LocalDate endDate) {
        String sql = "SELECT sc.id as category_id, sc.name as category_name, COUNT(r.id) as request_count, AVG(EXTRACT(EPOCH FROM (rh.updated_at - rh.created_at))/60) as avg_processing_minutes FROM request r JOIN request_history rh ON r.id = rh.request_id JOIN academic_service s ON r.academic_service_id = s.id JOIN service_category sc ON s.service_category_id = sc.id WHERE rh.created_at >= :startDate AND rh.created_at <= :endDate GROUP BY sc.id, sc.name ORDER BY request_count DESC";
        return jdbc.query(sql, Map.of("startDate", startDate, "endDate", endDate), (rs, rowNum) -> new ServiceUsageStats(rs.getInt("category_id"), rs.getString("category_name"), rs.getLong("request_count"), rs.getDouble("avg_processing_minutes")));
    }

    public List<RegistrarPerformanceStats> getRegistrarPerformanceStats(LocalDate startDate, LocalDate endDate) {
        String sql = "SELECT reg.id as registrar_id, reg.name as registrar_name, COUNT(DISTINCT r.id) as requests_processed, AVG(EXTRACT(EPOCH FROM (rh.updated_at - rh.created_at))/60) as avg_processing_minutes, COUNT(DISTINCT CASE WHEN r.current_phase = 4 THEN r.id END) as completed_requests FROM registrar reg LEFT JOIN request_history rh ON reg.id = rh.registrar_id LEFT JOIN request r ON rh.request_id = r.id WHERE rh.created_at >= :startDate AND rh.created_at <= :endDate GROUP BY reg.id, reg.name ORDER BY requests_processed DESC";
        return jdbc.query(sql, Map.of("startDate", startDate, "endDate", endDate), (rs, rowNum) -> new RegistrarPerformanceStats(rs.getInt("registrar_id"), rs.getString("registrar_name"), rs.getLong("requests_processed"), rs.getDouble("avg_processing_minutes"), rs.getLong("completed_requests")));
    }

    public DailyStats getDailyStats(LocalDate date) {
        String sql = "SELECT * FROM vw_daily_stats WHERE date = :date";
        return jdbc.query(sql, Map.of("date", date), (rs, rowNum) -> new DailyStats(rs.getObject("date", LocalDate.class), rs.getLong("total_active"), rs.getLong("waiting"), rs.getLong("pending"), rs.getLong("processing"), rs.getLong("completed"), rs.getLong("cancelled"))).stream().findFirst().orElse(null);
    }

    public List<DailyStats> getDailyStatsRange(LocalDate startDate, LocalDate endDate) {
        String sql = "SELECT * FROM vw_daily_stats WHERE date >= :startDate AND date <= :endDate ORDER BY date";
        return jdbc.query(sql, Map.of("startDate", startDate, "endDate", endDate), (rs, rowNum) -> new DailyStats(rs.getObject("date", LocalDate.class), rs.getLong("total_active"), rs.getLong("waiting"), rs.getLong("pending"), rs.getLong("processing"), rs.getLong("completed"), rs.getLong("cancelled")));
    }
}
