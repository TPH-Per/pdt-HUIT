package com.example.demo.controller;

import com.example.demo.dto.response.ApiResponse;
import com.example.demo.entity.Request;
import com.example.demo.entity.Registrar;
import com.example.demo.repository.RequestHistoryRepository;
import com.example.demo.repository.RequestRepository;
import com.example.demo.repository.RegistrarRepository;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * Controller Dashboard Phòng Đào tạo
 */
@RestController
@RequestMapping("/api/registrar/dashboard")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('Registrar') or hasRole('Admin')")
@Transactional
public class RegistrarDashboardController {

    private final RequestRepository requestRepository;
    private final RequestHistoryRepository requestHistoryRepository;
    private final RegistrarRepository registrarRepository;

    @Data
    @Builder
    public static class RegistrarDashboardData {
        private String tenCanBo;
        private String maCanBo;
        private String tenQuay;
        private String maQuay;
        private Integer tongSoChoHomNay;
        private Integer daXuLyHomNay;
        private Integer dangXuLy;
        private Integer tongHoSoDangXuLy;
        private Integer hoSoTreHan;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<RegistrarDashboardData>> getDashboard(Authentication authentication) {
        Registrar registrar = getCurrentRegistrar(authentication);
        LocalDate today = LocalDate.now();

        List<Request> todayReqs = requestHistoryRepository.findRequestsByAppointmentDate(today);

        int tongSoChoHomNay = (int) todayReqs.stream()
                .filter(a -> a.getCurrentPhase() == Request.PHASE_QUEUE)
                .count();

        int daXuLyHomNay = (int) todayReqs.stream()
                .filter(a -> a.getCurrentPhase() == Request.PHASE_COMPLETED)
                .count();

        int dangXuLy = (int) todayReqs.stream()
                .filter(a -> a.getCurrentPhase() == Request.PHASE_PROCESSING)
                .count();

        List<Request> allReqs = requestRepository.findAll();

        int tongHoSoDangXuLy = (int) allReqs.stream()
                .filter(a -> a.getCurrentPhase() == Request.PHASE_PENDING ||
                        a.getCurrentPhase() == Request.PHASE_PROCESSING)
                .count();

        int hoSoTreHan = (int) allReqs.stream()
                .filter(a -> a.getDeadline() != null &&
                        a.getDeadline().isBefore(today) &&
                        a.getCurrentPhase() != Request.PHASE_COMPLETED &&
                        a.getCurrentPhase() != Request.PHASE_CANCELLED)
                .count();

        RegistrarDashboardData dashboard = RegistrarDashboardData.builder()
                .tenCanBo(registrar.getFullName())
                .maCanBo(registrar.getRegistrarCode())
                .tenQuay(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getDeskName() : null)
                .maQuay(registrar.getServiceDesk() != null ? registrar.getServiceDesk().getDeskCode() : null)
                .tongSoChoHomNay(tongSoChoHomNay)
                .daXuLyHomNay(daXuLyHomNay)
                .dangXuLy(dangXuLy)
                .tongHoSoDangXuLy(tongHoSoDangXuLy)
                .hoSoTreHan(hoSoTreHan)
                .build();

        return ResponseEntity.ok(ApiResponse.success(dashboard));
    }

    private Registrar getCurrentRegistrar(Authentication authentication) {
        String registrarCode = authentication.getName();
        return registrarRepository.findByRegistrarCode(registrarCode)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ đào tạo"));
    }
}
