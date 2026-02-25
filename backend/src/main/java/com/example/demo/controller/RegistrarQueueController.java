package com.example.demo.controller;

import com.example.demo.dto.response.ApiResponse;
import com.example.demo.dto.response.RequestResponse;
import com.example.demo.dto.response.QueueDashboardResponse;
import com.example.demo.entity.Request;
import com.example.demo.entity.RequestHistory;
import com.example.demo.entity.Appointment;
import com.example.demo.entity.Registrar;
import com.example.demo.repository.RequestHistoryRepository;
import com.example.demo.repository.RequestRepository;
import com.example.demo.repository.AppointmentRepository;
import com.example.demo.repository.RegistrarRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Controller quản lý hàng chờ — Hệ thống quản lý Phòng Đào tạo
 */
@RestController
@RequestMapping("/api/registrar/queue")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('Registrar') or hasRole('Admin')")
@Transactional
public class RegistrarQueueController {

    private final RequestRepository requestRepository;
    private final RequestHistoryRepository requestHistoryRepository;
    private final AppointmentRepository appointmentRepository;
    private final RegistrarRepository registrarRepository;

    private static final List<LocalTime> MORNING_SLOTS = new ArrayList<>();
    private static final List<LocalTime> AFTERNOON_SLOTS = new ArrayList<>();

    static {
        LocalTime time = LocalTime.of(7, 30);
        for (int i = 0; i < 10; i++) {
            MORNING_SLOTS.add(time);
            time = time.plusMinutes(24);
        }
        time = LocalTime.of(13, 0);
        for (int i = 0; i < 10; i++) {
            AFTERNOON_SLOTS.add(time);
            time = time.plusMinutes(24);
        }
    }

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<QueueDashboardResponse>> getDashboard(Authentication authentication) {
        Registrar registrar = getCurrentRegistrar(authentication);

        if (registrar.getServiceDesk() == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("NO_DESK", "Bạn chưa được phân công quầy"));
        }

        LocalDate today = LocalDate.now();
        Integer deskId = registrar.getServiceDesk().getId();

        List<RequestHistory> waitingHistories = requestHistoryRepository.findActiveQueueHistories(today,
                Request.PHASE_QUEUE);

        List<Request> pendingReqs = requestHistoryRepository
                .findRequestsByAppointmentDateAndPhase(today, Request.PHASE_PENDING);

        List<Request> supplementReqs = requestHistoryRepository
                .findRequestsByAppointmentDateAndPhase(today, Request.PHASE_SUPPLEMENT);

        LocalTime nowTime = LocalTime.now();
        List<RequestResponse> waitingResponses = new ArrayList<>();

        for (RequestHistory h : waitingHistories) {
            if (h.getExpectedTime() != null && h.getExpectedTime().plusMinutes(24).isBefore(nowTime)) {
                Request req = h.getRequest();
                req.setCurrentPhase(Request.PHASE_CANCELLED);
                req.setCancelReason("Tự động hủy do trễ hẹn quá 24 phút");
                req.setCancelType(Request.CANCEL_NO_SHOW);
                requestRepository.save(req);

                RequestHistory cancelHistory = RequestHistory.builder()
                        .request(req)
                        .registrar(registrar)
                        .serviceDesk(registrar.getServiceDesk())
                        .action(RequestHistory.ACTION_CANCEL_NO_SHOW)
                        .phaseFrom(Request.PHASE_QUEUE)
                        .phaseTo(Request.PHASE_CANCELLED)
                        .content("Tự động hủy do quá giờ hẹn")
                        .createdAt(java.time.LocalDateTime.now())
                        .build();
                requestHistoryRepository.save(cancelHistory);

                log.info("Auto cancelled request {} due to late arrival", req.getRequestCode());
                continue;
            }

            RequestResponse res = mapToResponse(h.getRequest());
            res.setAppointmentDate(h.getAppointmentDate());
            res.setExpectedTime(h.getExpectedTime());
            waitingResponses.add(res);
        }

        for (Request req : pendingReqs) {
            RequestResponse res = mapToResponse(req);
            List<RequestHistory> histories = requestHistoryRepository
                    .findLatestAppointmentHistory(req.getId());
            if (!histories.isEmpty()) {
                res.setAppointmentDate(histories.get(0).getAppointmentDate());
                res.setExpectedTime(histories.get(0).getExpectedTime());
            }
            waitingResponses.add(res);
        }

        for (Request req : supplementReqs) {
            RequestResponse res = mapToResponse(req);
            List<RequestHistory> histories = requestHistoryRepository
                    .findLatestAppointmentHistory(req.getId());
            if (!histories.isEmpty()) {
                res.setAppointmentDate(histories.get(0).getAppointmentDate());
                res.setExpectedTime(histories.get(0).getExpectedTime());
            }
            waitingResponses.add(res);
        }

        try {
            waitingResponses.sort((a, b) -> {
                if (a.getExpectedTime() == null)
                    return 1;
                if (b.getExpectedTime() == null)
                    return -1;
                return a.getExpectedTime().compareTo(b.getExpectedTime());
            });
        } catch (Exception e) {
            // Ignore sort errors
        }

        List<Request> processingReqs = requestHistoryRepository
                .findRequestsByAppointmentDateAndPhase(today, Request.PHASE_PROCESSING);
        Request currentProcessing = processingReqs.isEmpty() ? null : processingReqs.get(0);

        Long totalCompleted = requestHistoryRepository.countByAppointmentDateAndPhase(today,
                Request.PHASE_COMPLETED);
        Long totalCancelled = requestHistoryRepository.countByAppointmentDateAndPhase(today,
                Request.PHASE_CANCELLED);

        QueueDashboardResponse dashboard = QueueDashboardResponse.builder()
                .deskId(deskId)
                .deskName(registrar.getServiceDesk().getDeskName())
                .deskCode(registrar.getServiceDesk().getDeskCode())
                .currentProcessing(currentProcessing != null ? mapToResponse(currentProcessing) : null)
                .waitingList(waitingResponses)
                .totalWaiting(waitingResponses.size())
                .totalCompleted(totalCompleted != null ? totalCompleted.intValue() : 0)
                .totalCancelled(totalCancelled != null ? totalCancelled.intValue() : 0)
                .averageProcessingTime(15)
                .build();

        return ResponseEntity.ok(ApiResponse.success(dashboard));
    }

    @GetMapping("/waiting")
    public ResponseEntity<ApiResponse<List<RequestResponse>>> getWaitingList() {
        LocalDate today = LocalDate.now();
        List<Request> waitingReqs = requestHistoryRepository
                .findRequestsByAppointmentDateAndPhase(today, Request.PHASE_QUEUE);
        List<Request> pendingReqs = requestHistoryRepository
                .findRequestsByAppointmentDateAndPhase(today, Request.PHASE_PENDING);
        List<Request> supplementReqs = requestHistoryRepository
                .findRequestsByAppointmentDateAndPhase(today, Request.PHASE_SUPPLEMENT);

        List<RequestResponse> responses = new ArrayList<>();
        for (Request req : waitingReqs)
            responses.add(mapToResponse(req));
        for (Request req : pendingReqs)
            responses.add(mapToResponse(req));
        for (Request req : supplementReqs)
            responses.add(mapToResponse(req));

        return ResponseEntity.ok(ApiResponse.success(responses));
    }

    @GetMapping("/current")
    public ResponseEntity<ApiResponse<RequestResponse>> getCurrentProcessing(Authentication authentication) {
        LocalDate today = LocalDate.now();
        List<Request> processingReqs = requestHistoryRepository
                .findRequestsByAppointmentDateAndPhase(today, Request.PHASE_PROCESSING);
        Request currentProcessing = processingReqs.isEmpty() ? null : processingReqs.get(0);
        return ResponseEntity.ok(ApiResponse.success(
                currentProcessing != null ? mapToResponse(currentProcessing) : null));
    }

    @PostMapping("/call-next")
    public ResponseEntity<ApiResponse<RequestResponse>> callNext(
            @RequestBody(required = false) Map<String, Integer> body,
            Authentication authentication) {
        Registrar registrar = getCurrentRegistrar(authentication);
        LocalDate today = LocalDate.now();

        List<Request> currentProcessingList = requestHistoryRepository
                .findRequestsByAppointmentDateAndPhase(today, Request.PHASE_PROCESSING);

        if (!currentProcessingList.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("HAS_PROCESSING",
                            "Vui lòng hoàn thành lượt hiện tại trước"));
        }

        Request nextReq = null;
        Integer requestedId = (body != null) ? body.get("id") : null;

        if (requestedId != null) {
            nextReq = requestRepository.findById(requestedId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu"));
            if (nextReq.getCurrentPhase() != Request.PHASE_QUEUE
                    && nextReq.getCurrentPhase() != Request.PHASE_PENDING
                    && nextReq.getCurrentPhase() != Request.PHASE_SUPPLEMENT) {
                return ResponseEntity.badRequest().body(
                        ApiResponse.error("INVALID_STATUS",
                                "Yêu cầu không ở trong hàng chờ hoặc danh sách hẹn"));
            }
        } else {
            List<Request> waitingReqs = requestHistoryRepository
                    .findRequestsByAppointmentDateAndPhase(today, Request.PHASE_QUEUE);
            if (waitingReqs.isEmpty()) {
                return ResponseEntity.ok(
                        ApiResponse.success(null, "Không còn ai trong hàng chờ (đã check-in)"));
            }
            nextReq = waitingReqs.get(0);
        }

        nextReq.setCurrentPhase(Request.PHASE_PROCESSING);
        nextReq = requestRepository.save(nextReq);

        saveHistory(nextReq, registrar, "GỌI SỐ",
                Request.PHASE_QUEUE, Request.PHASE_PROCESSING,
                "Gọi số " + nextReq.getQueueDisplay());

        log.info("Called next: {} by {}", nextReq.getQueueDisplay(), registrar.getRegistrarCode());

        return ResponseEntity.ok(
                ApiResponse.success(mapToResponse(nextReq), "Đã gọi số " + nextReq.getQueueDisplay()));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<ApiResponse<RequestResponse>> complete(
            @PathVariable Integer id,
            @RequestBody(required = false) Map<String, String> body,
            Authentication authentication) {

        Registrar registrar = getCurrentRegistrar(authentication);
        Request req = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu"));

        int oldPhase = req.getCurrentPhase();
        if (oldPhase != Request.PHASE_PROCESSING && oldPhase != Request.PHASE_RECEIVED) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_STATE",
                            "Yêu cầu không ở trạng thái đang xử lý"));
        }

        req.setCurrentPhase(Request.PHASE_COMPLETED);
        req = requestRepository.save(req);

        String ghiChu = body != null ? body.get("ghiChu") : null;
        saveHistory(req, registrar, "HOÀN THÀNH",
                oldPhase, Request.PHASE_COMPLETED,
                ghiChu != null ? ghiChu : "Hoàn thành xử lý");

        List<Appointment> activeApps = appointmentRepository.findActiveByRequestId(req.getId());
        for (Appointment a : activeApps) {
            a.setStatus(Appointment.STATUS_COMPLETED);
            appointmentRepository.save(a);
        }

        log.info("Completed: {} by {}", req.getQueueDisplay(), registrar.getRegistrarCode());
        return ResponseEntity.ok(ApiResponse.success(mapToResponse(req), "Đã hoàn thành"));
    }

    @PostMapping("/{id}/receive")
    public ResponseEntity<ApiResponse<RequestResponse>> receive(
            @PathVariable Integer id,
            @RequestBody(required = false) Map<String, String> body,
            Authentication authentication) {

        Registrar registrar = getCurrentRegistrar(authentication);
        Request req = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu"));

        if (req.getCurrentPhase() != Request.PHASE_PROCESSING) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_STATE",
                            "Yêu cầu không ở trạng thái đang xử lý"));
        }

        String appointmentDateStr = body != null ? body.get("appointmentDate") : null;
        String expectedTimeStr = body != null ? body.get("expectedTime") : null;

        String historyContent = "Đã tiếp nhận yêu cầu";
        if (appointmentDateStr != null) {
            try {
                LocalDate deadline = LocalDate.parse(appointmentDateStr);
                req.setDeadline(deadline);
                historyContent += ". Hẹn trả: " + deadline;
                if (expectedTimeStr != null) {
                    historyContent += " " + expectedTimeStr;
                }
            } catch (Exception e) {
                log.warn("Invalid date format: {}", appointmentDateStr);
            }
        }

        req.setCurrentPhase(Request.PHASE_RECEIVED);
        req = requestRepository.save(req);

        saveHistory(req, registrar, "TIẾP NHẬN",
                Request.PHASE_PROCESSING, Request.PHASE_RECEIVED,
                historyContent);

        log.info("Received: {} by {}", req.getQueueDisplay(), registrar.getRegistrarCode());
        return ResponseEntity.ok(ApiResponse.success(mapToResponse(req), "Đã tiếp nhận yêu cầu"));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<RequestResponse>> cancel(
            @PathVariable Integer id,
            @RequestBody Map<String, Object> body,
            Authentication authentication) {

        Registrar registrar = getCurrentRegistrar(authentication);
        Request req = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu"));

        String lyDo = (String) body.get("lyDo");
        Integer trangThai = body.get("trangThai") != null
                ? ((Number) body.get("trangThai")).intValue()
                : Request.CANCEL_NO_SHOW;

        int oldPhase = req.getCurrentPhase();
        req.setCurrentPhase(Request.PHASE_CANCELLED);
        req.setCancelReason(lyDo);
        req.setCancelType(trangThai);
        req = requestRepository.save(req);

        saveHistory(req, registrar, "HỦY", oldPhase, Request.PHASE_CANCELLED, lyDo);

        List<Appointment> appointments = appointmentRepository.findActiveByRequestId(req.getId());
        for (Appointment a : appointments) {
            a.setStatus(Appointment.STATUS_CANCELLED);
            appointmentRepository.save(a);
        }

        log.info("Cancelled: {} by {} - reason: {}", req.getQueueDisplay(), registrar.getRegistrarCode(), lyDo);
        return ResponseEntity.ok(ApiResponse.success(mapToResponse(req), "Đã hủy lượt"));
    }

    @GetMapping("/slots")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getSlots(@RequestParam LocalDate date) {
        List<LocalTime> bookedTimes = appointmentRepository.findBookedTimes(date);

        List<Map<String, Object>> morning = new ArrayList<>();
        for (LocalTime slot : MORNING_SLOTS) {
            Map<String, Object> slotInfo = new HashMap<>();
            slotInfo.put("time", slot.toString());
            slotInfo.put("booked", bookedTimes.contains(slot));
            morning.add(slotInfo);
        }

        List<Map<String, Object>> afternoon = new ArrayList<>();
        for (LocalTime slot : AFTERNOON_SLOTS) {
            Map<String, Object> slotInfo = new HashMap<>();
            slotInfo.put("time", slot.toString());
            slotInfo.put("booked", bookedTimes.contains(slot));
            afternoon.add(slotInfo);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("morning", morning);
        result.put("afternoon", afternoon);

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @PostMapping("/{id}/supplement")
    public ResponseEntity<ApiResponse<RequestResponse>> supplement(
            @PathVariable Integer id,
            @RequestBody Map<String, String> body,
            Authentication authentication) {

        Registrar registrar = getCurrentRegistrar(authentication);
        Request req = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu"));

        String dateStr = body.get("appointmentDate");
        String timeStr = body.get("appointmentTime");

        if (dateStr == null || timeStr == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("MISSING_DATA", "Thiếu ngày giờ hẹn"));
        }

        LocalDate date = LocalDate.parse(dateStr);
        LocalTime time = LocalTime.parse(timeStr.length() == 5 ? timeStr + ":00" : timeStr);

        int oldPhase = req.getCurrentPhase();
        req.setCurrentPhase(Request.PHASE_QUEUE);
        req = requestRepository.save(req);

        RequestHistory history = RequestHistory.builder()
                .request(req)
                .serviceDesk(registrar.getServiceDesk())
                .registrar(registrar)
                .action(RequestHistory.ACTION_RESCHEDULE)
                .phaseFrom(oldPhase)
                .phaseTo(Request.PHASE_QUEUE)
                .content("Hẹn bổ sung hồ sơ. Ngày hẹn: " + date + " " + time)
                .appointmentDate(date)
                .expectedTime(time)
                .createdAt(java.time.LocalDateTime.now())
                .build();
        requestHistoryRepository.save(history);

        Appointment appointment = Appointment.builder()
                .request(req)
                .registrar(registrar)
                .appointmentDate(date)
                .appointmentTime(time)
                .status(Appointment.STATUS_SCHEDULED)
                .build();
        appointmentRepository.save(appointment);

        log.info("Supplement scheduled: {} at {} {} by {}", req.getRequestCode(), date, time,
                registrar.getRegistrarCode());
        return ResponseEntity.ok(ApiResponse.success(mapToResponse(req), "Đã đặt lịch bổ sung"));
    }

    // ==================== HELPER METHODS ====================

    private Registrar getCurrentRegistrar(Authentication authentication) {
        String registrarCode = authentication.getName();
        return registrarRepository.findByRegistrarCode(registrarCode)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ đào tạo"));
    }

    private void saveHistory(Request req, Registrar registrar, String action,
            int oldPhase, int newPhase, String content) {
        RequestHistory history = RequestHistory.builder()
                .request(req)
                .serviceDesk(registrar.getServiceDesk())
                .registrar(registrar)
                .action(action)
                .phaseFrom(oldPhase)
                .phaseTo(newPhase)
                .content(content)
                .createdAt(java.time.LocalDateTime.now())
                .build();
        requestHistoryRepository.save(history);
    }

    private RequestResponse mapToResponse(Request req) {
        List<RequestHistory> appointments = requestHistoryRepository
                .findLatestAppointmentHistory(req.getId());

        LocalDate appointmentDate = null;
        java.time.LocalTime expectedTime = null;

        if (!appointments.isEmpty()) {
            RequestHistory latest = appointments.get(0);
            appointmentDate = latest.getAppointmentDate();
            expectedTime = latest.getExpectedTime();
        }

        return RequestResponse.builder()
                .id(req.getId())
                .requestCode(req.getRequestCode())
                .serviceId(req.getAcademicService().getId())
                .serviceCode(req.getAcademicService().getServiceCode())
                .serviceName(req.getAcademicService().getServiceName())
                .studentId(req.getStudent().getStudentId())
                .studentName(req.getStudent().getFullName())
                .studentPhone(req.getStudent().getPhone())
                .currentPhase(req.getCurrentPhase())
                .phaseName(RequestResponse.getPhaseName(req.getCurrentPhase()))
                .queueNumber(req.getQueueNumber())
                .queuePrefix(req.getQueuePrefix())
                .queueDisplay(req.getQueueDisplay())
                .appointmentDate(appointmentDate)
                .expectedTime(expectedTime)
                .deadline(req.getDeadline())
                .priority(req.getPriority())
                .priorityName(RequestResponse.getPriorityName(req.getPriority()))
                .cancelReason(req.getCancelReason())
                .cancelType(req.getCancelType())
                .createdAt(req.getCreatedAt())
                .updatedAt(req.getUpdatedAt())
                .build();
    }
}
