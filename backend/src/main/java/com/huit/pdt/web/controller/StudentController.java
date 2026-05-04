package com.huit.pdt.web.controller;

import com.huit.pdt.web.dto.ApiResponse;
import com.huit.pdt.infrastructure.persistence.*;
import com.huit.pdt.infrastructure.persistence.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.text.Normalizer;

/**
 * Student Controller - API cho sinh viên (Client App)
 * Không yêu cầu xác thực Staff, chỉ cần MSSV
 */
@RestController
@RequestMapping("/api/student")
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class StudentController {

    private final RequestRepository requestRepository;
    private final RequestHistoryRepository requestHistoryRepository;
    private final AppointmentRepository appointmentRepository;
    private final AcademicServiceRepository academicServiceRepository;
    private final ServiceCategoryRepository serviceCategoryRepository;
    private final ServiceDeskRepository serviceDeskRepository;
    private final StudentRepository studentRepository;
    private final ReportRepository reportRepository;
    private final ReplyRepository replyRepository;
    private final FeedbackRepository feedbackRepository;
    private final PasswordEncoder passwordEncoder;

    // Default password hash for '123456' – used when auto-creating student from
    // appointment form
    private static final String DEFAULT_PASSWORD_HASH = "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy";

    // ==================== DỊCH VỤ HỌC VỤ ====================

    @GetMapping("/categories")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getCategories() {
        List<ServiceCategory> types = serviceCategoryRepository.findAll();

        List<Map<String, Object>> result = types.stream().map(t -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", t.getId());
            map.put("name", t.getName());
            map.put("description", t.getDescription());
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @GetMapping("/services")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getServices(
            @RequestParam(required = false) Integer categoryId) {

        List<AcademicService> services;
        if (categoryId != null) {
            services = academicServiceRepository.findByCategoryIdAndIsActive(categoryId, true);
        } else {
            services = academicServiceRepository.findAllActive();
        }

        List<Map<String, Object>> result = services.stream().map(p -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", p.getId());
            map.put("name", p.getServiceName());
            map.put("code", p.getServiceCode());
            map.put("categoryId", p.getServiceCategory() != null ? p.getServiceCategory().getId() : null);
            map.put("estimatedDays", p.getProcessingDays());
            map.put("description", p.getDescription());
            map.put("requiredDocuments", p.getRequiredDocuments());
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    // ==================== LỊCH HẸN ====================

    @GetMapping("/appointments/available-slots")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAvailableSlots(
            @RequestParam String date,
            @RequestParam(required = false) Integer serviceId) {

        LocalDate targetDate = LocalDate.parse(date);

        int maxCapacity = 5;
        List<LocalTime> bookedTimes = new ArrayList<>();

        if (serviceId != null) {
            Optional<AcademicService> serviceOpt = academicServiceRepository.findById(serviceId);
            if (serviceOpt.isPresent()) {
                Integer categoryId = serviceOpt.get().getServiceCategory().getId();
                List<ServiceDesk> desks = serviceDeskRepository.findByCategoryId(categoryId);
                maxCapacity = desks.isEmpty() ? 1 : desks.size();
                bookedTimes = appointmentRepository.findBookedTimesByCategory(targetDate, categoryId);
            } else {
                bookedTimes = appointmentRepository.findBookedTimes(targetDate);
            }
        } else {
            bookedTimes = appointmentRepository.findBookedTimes(targetDate);
        }

        List<Map<String, Object>> slots = new ArrayList<>();

        LocalTime morningStart = LocalTime.of(7, 30);
        for (int i = 0; i < 10; i++) {
            LocalTime slotTime = morningStart.plusMinutes(i * 24);
            int bookedCount = Collections.frequency(bookedTimes, slotTime);
            int available = Math.max(0, maxCapacity - bookedCount);

            Map<String, Object> slot = new HashMap<>();
            slot.put("time", slotTime.toString());
            slot.put("available", available);
            slot.put("maxCapacity", maxCapacity);
            slots.add(slot);
        }

        LocalTime afternoonStart = LocalTime.of(13, 0);
        for (int i = 0; i < 10; i++) {
            LocalTime slotTime = afternoonStart.plusMinutes(i * 24);
            int bookedCount = Collections.frequency(bookedTimes, slotTime);
            int available = Math.max(0, maxCapacity - bookedCount);

            Map<String, Object> slot = new HashMap<>();
            slot.put("time", slotTime.toString());
            slot.put("available", available);
            slot.put("maxCapacity", maxCapacity);
            slots.add(slot);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("date", date);
        result.put("slots", slots);

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @Transactional
    @PostMapping("/appointments")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createAppointment(
            @RequestBody Map<String, Object> body) {

        Integer serviceId = ((Number) body.get("serviceId")).intValue();
        String appointmentDateStr = (String) body.get("appointmentDate");
        String appointmentTimeStr = (String) body.get("appointmentTime");
        String studentName = (String) body.get("studentName");
        String studentId = (String) body.get("studentId");
        String phoneNumber = (String) body.get("phoneNumber");

        if (serviceId == null || appointmentDateStr == null || appointmentTimeStr == null ||
                studentName == null || studentId == null || phoneNumber == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("MISSING_FIELDS", "Thiếu thông tin bắt buộc"));
        }

        if (studentId.length() != 10) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_MSSV", "MSSV phải có đúng 10 ký tự"));
        }

        Optional<Student> existingStudent = studentRepository.findByStudentId(studentId);
        if (existingStudent.isPresent()) {
            String existingName = normalizeString(existingStudent.get().getFullName());
            String newName = normalizeString(studentName);

            if (!existingName.equals(newName)) {
                return ResponseEntity.status(409)
                        .body(ApiResponse.error("STUDENT_CONFLICT",
                                "MSSV " + studentId + " đã được đăng ký với tên: " + existingStudent.get().getFullName()
                                        + ". Vui lòng kiểm tra lại thông tin hoặc liên hệ hỗ trợ."));
            }
        }

        AcademicService service = academicServiceRepository.findById(serviceId)
                .orElseThrow(() -> new RuntimeException("Dịch vụ không tồn tại"));

        LocalDate appointmentDate = LocalDate.parse(appointmentDateStr);
        LocalTime appointmentTime = LocalTime.parse(appointmentTimeStr);

        boolean alreadyBooked = appointmentRepository.existsByStudentAndDateTime(studentId, appointmentDate,
                appointmentTime);
        if (alreadyBooked) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("DUPLICATE_APPOINTMENT",
                            "Bạn đã có lịch hẹn được đặt vào ngày giờ này rồi. Không thể đặt thêm."));
        }

        Student student = studentRepository.findByStudentId(studentId)
                .orElseGet(() -> {
                    Student newStudent = Student.builder()
                            .studentId(studentId)
                            .fullName(studentName)
                            .phone(phoneNumber)
                            .passwordHash(DEFAULT_PASSWORD_HASH)
                            .build();
                    return studentRepository.save(newStudent);
                });

        student.setFullName(studentName);
        student.setPhone(phoneNumber);
        studentRepository.save(student);

        int queueNumber = requestRepository.countByCreatedAtDate(LocalDate.now()) + 1;
        String prefix = service.getServiceCode().substring(0, Math.min(2, service.getServiceCode().length()));

        Request req = Request.builder()
                .requestCode(
                        "RQ-" + LocalDate.now().toString().replace("-", "") + "-" + String.format("%03d", queueNumber))
                .academicService(service)
                .student(student)
                .currentPhase(Request.PHASE_PENDING)
                .priority(Request.PRIORITY_NORMAL)
                .queueNumber(queueNumber)
                .queuePrefix(prefix)
                .build();
        req = requestRepository.save(req);

        Appointment appointment = Appointment.builder()
                .request(req)
                .appointmentDate(appointmentDate)
                .appointmentTime(appointmentTime)
                .status(Appointment.STATUS_SCHEDULED)
                .build();
        appointmentRepository.save(appointment);

        RequestHistory history = RequestHistory.builder()
                .request(req)
                .action("ĐẶT LỊCH")
                .phaseFrom(null)
                .phaseTo(Request.PHASE_PENDING)
                .content("Đặt lịch hẹn qua App")
                .appointmentDate(appointmentDate)
                .expectedTime(appointmentTime)
                .createdAt(LocalDateTime.now())
                .build();
        requestHistoryRepository.save(history);

        log.info("Student {} created appointment for service {}",
                studentId, service.getServiceCode());

        Map<String, Object> result = new HashMap<>();
        result.put("id", req.getId());
        result.put("code", req.getRequestCode());
        result.put("serviceName", service.getServiceName());
        result.put("appointmentDate", appointmentDate.toString());
        result.put("appointmentTime", appointmentTime.toString());
        result.put("queueDisplay", req.getQueueDisplay());
        result.put("status", "SCHEDULED");

        return ResponseEntity.ok(ApiResponse.success(result, "Đặt lịch thành công"));
    }

    @GetMapping("/appointments")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getAppointments(
            @RequestParam String mssv,
            @RequestParam(required = false) String status) {

        List<Request> reqs = requestRepository.findByStudentStudentId(mssv);

        if (status != null) {
            reqs = reqs.stream().filter(req -> {
                switch (status.toUpperCase()) {
                    case "UPCOMING":
                        return req.getCurrentPhase() == Request.PHASE_PENDING
                                || req.getCurrentPhase() == Request.PHASE_QUEUE;
                    case "COMPLETED":
                        return req.getCurrentPhase() == Request.PHASE_COMPLETED;
                    case "CANCELLED":
                        return req.getCurrentPhase() == Request.PHASE_CANCELLED;
                    default:
                        return true;
                }
            }).collect(Collectors.toList());
        }

        List<Map<String, Object>> result = reqs.stream().map(req -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", req.getId());
            map.put("code", req.getRequestCode());
            map.put("serviceName", req.getAcademicService().getServiceName());
            map.put("status", getStatusName(req.getCurrentPhase()));
            map.put("queueDisplay", req.getQueueDisplay());
            map.put("createdAt", req.getCreatedAt());

            List<RequestHistory> histories = requestHistoryRepository.findLatestAppointmentHistory(req.getId());
            if (!histories.isEmpty()) {
                map.put("appointmentDate", histories.get(0).getAppointmentDate());
                map.put("appointmentTime", histories.get(0).getExpectedTime());
            }

            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @Transactional
    @PostMapping("/appointments/{id}/cancel")
    public ResponseEntity<ApiResponse<Object>> cancelAppointment(
            @PathVariable Integer id,
            @RequestParam String mssv) {

        Request req = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lịch hẹn"));

        if (!req.getStudent().getStudentId().equals(mssv)) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("UNAUTHORIZED", "Bạn không có quyền hủy lịch hẹn này"));
        }

        if (req.getCurrentPhase() != Request.PHASE_PENDING && req.getCurrentPhase() != Request.PHASE_QUEUE) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("INVALID_STATUS", "Không thể hủy lịch hẹn ở trạng thái này"));
        }

        int oldPhase = req.getCurrentPhase();
        req.setCurrentPhase(Request.PHASE_CANCELLED);
        req.setCancelReason("Sinh viên tự hủy");
        req.setCancelType(Request.CANCEL_SELF);
        requestRepository.save(req);

        List<Appointment> appointments = appointmentRepository.findActiveByRequestId(req.getId());
        for (Appointment a : appointments) {
            a.setStatus(Appointment.STATUS_CANCELLED);
            appointmentRepository.save(a);
        }

        RequestHistory history = RequestHistory.builder()
                .request(req)
                .action("HỦY LỊCH")
                .phaseFrom(oldPhase)
                .phaseTo(Request.PHASE_CANCELLED)
                .content("Sinh viên tự hủy lịch hẹn")
                .createdAt(LocalDateTime.now())
                .build();
        requestHistoryRepository.save(history);

        return ResponseEntity.ok(ApiResponse.success(null, "Đã hủy lịch hẹn"));
    }

    @GetMapping("/appointments/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getAppointmentById(
            @PathVariable Integer id,
            @RequestParam String mssv) {

        Request req = requestRepository.findById(id).orElse(null);

        if (req == null) {
            return ResponseEntity.status(404)
                    .body(ApiResponse.error("NOT_FOUND", "Không tìm thấy lịch hẹn"));
        }

        if (!req.getStudent().getStudentId().equals(mssv)) {
            return ResponseEntity.status(403)
                    .body(ApiResponse.error("FORBIDDEN", "Bạn không có quyền xem lịch hẹn này"));
        }

        Map<String, Object> result = new HashMap<>();
        result.put("id", req.getId());
        result.put("code", req.getRequestCode());
        result.put("serviceName", req.getAcademicService().getServiceName());
        result.put("serviceCode", req.getAcademicService().getServiceCode());
        result.put("status", getStatusName(req.getCurrentPhase()));
        result.put("queueDisplay", req.getQueueDisplay());
        result.put("queueNumber", req.getQueueNumber());
        result.put("studentName", req.getStudent().getFullName());
        result.put("createdAt", req.getCreatedAt());
        result.put("deadline", req.getDeadline());

        int queuePosition = 0;
        if (req.getCurrentPhase() == Request.PHASE_QUEUE || req.getCurrentPhase() == Request.PHASE_PENDING) {
            LocalDate today = LocalDate.now();
            List<Request> queueReqs = requestRepository.findAll().stream()
                    .filter(a -> (a.getCurrentPhase() == Request.PHASE_QUEUE
                            || a.getCurrentPhase() == Request.PHASE_PENDING))
                    .filter(a -> a.getCreatedAt() != null && a.getCreatedAt().toLocalDate().equals(today))
                    .filter(a -> a.getQueueNumber() != null && a.getQueueNumber() < req.getQueueNumber())
                    .toList();
            queuePosition = queueReqs.size();
        }
        result.put("peopleAhead", queuePosition);
        result.put("estimatedWaitMinutes", queuePosition * 15);
        result.put("currentServing", null);

        List<RequestHistory> histories = requestHistoryRepository.findLatestAppointmentHistory(req.getId());
        if (!histories.isEmpty()) {
            result.put("appointmentDate", histories.get(0).getAppointmentDate());
            result.put("appointmentTime", histories.get(0).getExpectedTime());
        }

        result.put("desk", null);

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    // ==================== YÊU CẦU ====================

    @GetMapping("/requests")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getRequests(
            @RequestParam String mssv,
            @RequestParam(required = false) String status) {
        return getAppointments(mssv, status);
    }

    @GetMapping("/requests/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getRequestDetail(
            @PathVariable Integer id,
            @RequestParam String mssv) {

        Request req = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu"));

        if (!req.getStudent().getStudentId().equals(mssv)) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("UNAUTHORIZED", "Bạn không có quyền xem yêu cầu này"));
        }

        Map<String, Object> result = new HashMap<>();
        result.put("id", req.getId());
        result.put("code", req.getRequestCode());
        result.put("serviceName", req.getAcademicService().getServiceName());
        result.put("serviceCode", req.getAcademicService().getServiceCode());
        result.put("status", getStatusName(req.getCurrentPhase()));
        result.put("statusCode", req.getCurrentPhase());
        result.put("queueDisplay", req.getQueueDisplay());
        result.put("createdAt", req.getCreatedAt());
        result.put("deadline", req.getDeadline());

        result.put("studentName", req.getStudent().getFullName());
        result.put("studentId", req.getStudent().getStudentId());
        result.put("phone", req.getStudent().getPhone());

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @GetMapping("/requests/{id}/history")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getRequestHistory(
            @PathVariable Integer id,
            @RequestParam String mssv) {

        Request req = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu"));

        if (!req.getStudent().getStudentId().equals(mssv)) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("UNAUTHORIZED", "Bạn không có quyền xem yêu cầu này"));
        }

        List<RequestHistory> histories = requestHistoryRepository.findByRequestId(id);

        List<Map<String, Object>> result = histories.stream().map(h -> {
            Map<String, Object> map = new HashMap<>();
            map.put("action", h.getAction());
            map.put("content", h.getContent());
            map.put("createdAt", h.getCreatedAt());
            map.put("registrarName", h.getRegistrar() != null ? h.getRegistrar().getFullName() : "Hệ thống");
            map.put("statusFrom", getStatusName(h.getPhaseFrom()));
            map.put("statusTo", getStatusName(h.getPhaseTo()));
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    // ==================== HÀNG CHỜ ====================

    @GetMapping("/queue/{ticketCode}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getQueueStatus(
            @PathVariable String ticketCode) {

        Request foundReq = requestRepository.findByRequestCode(ticketCode).orElse(null);

        if (foundReq == null) {
            foundReq = requestRepository.findByQueueDisplay(ticketCode).orElse(null);
        }

        if (foundReq == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("NOT_FOUND", "Không tìm thấy số thứ tự"));
        }

        final Request req = foundReq;
        LocalDate today = LocalDate.now();

        long waitingCount = 0;
        Integer reqQueueNum = req.getQueueNumber() != null ? req.getQueueNumber() : 0;
        if (req.getCurrentPhase() == Request.PHASE_QUEUE || req.getCurrentPhase() == Request.PHASE_PENDING) {
            List<Request> allWaiting = requestHistoryRepository.findRequestsByAppointmentDate(today);
            final int finalReqQueueNum = reqQueueNum;
            waitingCount = allWaiting.stream()
                    .filter(a -> (a.getCurrentPhase() == Request.PHASE_QUEUE
                            || a.getCurrentPhase() == Request.PHASE_PENDING)
                            && a.getQueueNumber() != null
                            && a.getQueueNumber() < finalReqQueueNum)
                    .count();
        }

        List<Request> processing = requestHistoryRepository.findRequestsByAppointmentDateAndPhase(today,
                Request.PHASE_PROCESSING);
        int currentServing = processing.isEmpty() ? 0
                : (processing.get(0).getQueueNumber() != null ? processing.get(0).getQueueNumber() : 0);

        Map<String, Object> result = new HashMap<>();
        result.put("ticketNumber", req.getQueueNumber());
        result.put("ticketDisplay", req.getQueueDisplay());
        result.put("currentServing", currentServing);
        result.put("waitingCount", waitingCount);
        result.put("estimatedWaitMinutes", waitingCount * 15);
        result.put("status", getQueueStatusName(req.getCurrentPhase()));
        result.put("serviceName", req.getAcademicService().getServiceName());

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    // ==================== GÓP Ý / PHẢN HỒI ====================

    @Transactional
    @PostMapping("/reports")
    public ResponseEntity<ApiResponse<Map<String, Object>>> createReport(
            @RequestBody Map<String, Object> body) {

        Integer type = ((Number) body.get("type")).intValue();
        Integer requestId = body.get("requestId") != null ? ((Number) body.get("requestId")).intValue() : null;
        String title = (String) body.get("title");
        String content = (String) body.get("content");
        String studentIdStr = (String) body.get("studentId");
        String studentName = (String) body.get("studentName");
        String phone = (String) body.get("phone");

        if (title == null || content == null || studentIdStr == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("MISSING_FIELDS", "Thiếu thông tin bắt buộc"));
        }

        Request req = null;
        if (requestId != null) {
            req = requestRepository.findById(requestId).orElse(null);
        }

        Student student = studentRepository.findByStudentId(studentIdStr)
                .orElseGet(() -> {
                    Student newStudent = Student.builder()
                            .studentId(studentIdStr)
                            .fullName(studentName != null ? studentName : "Sinh viên")
                            .phone(phone)
                            .passwordHash(DEFAULT_PASSWORD_HASH)
                            .build();
                    return studentRepository.save(newStudent);
                });

        Feedback feedback = Feedback.builder()
                .student(student)
                .request(req)
                .type(type)
                .title(title)
                .content(content)
                .status(0)
                .build();
        feedback = feedbackRepository.save(feedback);

        log.info("Student {} created feedback: {}", studentIdStr, title);

        Map<String, Object> result = new HashMap<>();
        result.put("id", feedback.getId());
        result.put("title", feedback.getTitle());
        result.put("status", "PENDING");

        return ResponseEntity.ok(ApiResponse.success(result, "Gửi góp ý thành công"));
    }

    @GetMapping("/reports")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getReports(
            @RequestParam String mssv) {

        List<Feedback> feedbacks = feedbackRepository.findByStudentStudentId(mssv);

        List<Map<String, Object>> result = feedbacks.stream().map(f -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", f.getId());
            map.put("type", f.getType());
            map.put("title", f.getTitle());
            map.put("status", getReportStatusName(f.getStatus()));
            map.put("createdAt", f.getCreatedAt());
            if (f.getRequest() != null) {
                map.put("requestCode", f.getRequest().getRequestCode());
            }
            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    // ==================== STUDENT PROFILE ====================

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getProfile(@RequestParam String mssv) {
        Student student = studentRepository.findByStudentId(mssv).orElse(null);
        if (student == null) {
            return ResponseEntity.status(404)
                    .body(ApiResponse.error("NOT_FOUND", "Không tìm thấy sinh viên"));
        }

        Map<String, Object> profile = new HashMap<>();
        profile.put("studentId", student.getStudentId());
        profile.put("fullName", student.getFullName());
        profile.put("major", student.getMajor());
        profile.put("dateOfBirth", student.getDateOfBirth());
        profile.put("gender", student.getGender());
        profile.put("phone", student.getPhone());
        profile.put("email", student.getEmail());
        profile.put("createdAt", student.getCreatedAt());

        return ResponseEntity.ok(ApiResponse.success(profile));
    }

    @PutMapping("/profile")
    @Transactional
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateProfile(@RequestBody Map<String, String> body) {
        String mssv = body.get("mssv");
        if (mssv == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("MISSING_FIELDS", "Thiếu MSSV"));
        }

        Student student = studentRepository.findByStudentId(mssv).orElse(null);
        if (student == null) {
            return ResponseEntity.status(404)
                    .body(ApiResponse.error("NOT_FOUND", "Không tìm thấy sinh viên"));
        }

        if (body.containsKey("phone"))
            student.setPhone(body.get("phone"));
        if (body.containsKey("email"))
            student.setEmail(body.get("email"));
        if (body.containsKey("fullName"))
            student.setFullName(body.get("fullName"));

        studentRepository.save(student);
        log.info("Student profile updated: {}", mssv);

        Map<String, Object> profile = new HashMap<>();
        profile.put("studentId", student.getStudentId());
        profile.put("fullName", student.getFullName());
        profile.put("phone", student.getPhone());
        profile.put("email", student.getEmail());

        return ResponseEntity.ok(ApiResponse.success(profile, "Cập nhật thông tin thành công"));
    }

    // ==================== STUDENT FEEDBACK ====================

    @PostMapping("/feedback")
    @Transactional
    public ResponseEntity<ApiResponse<Map<String, Object>>> submitFeedback(@RequestBody Map<String, Object> body) {
        String mssv = (String) body.get("mssv");
        String title = (String) body.get("title");
        String content = (String) body.get("content");
        Integer type = body.get("type") != null ? ((Number) body.get("type")).intValue() : Feedback.TYPE_SUGGESTION;

        if (mssv == null || title == null) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("MISSING_FIELDS", "Thiếu MSSV hoặc tiêu đề"));
        }

        Student student = studentRepository.findByStudentId(mssv).orElse(null);
        if (student == null) {
            return ResponseEntity.status(404)
                    .body(ApiResponse.error("NOT_FOUND", "Không tìm thấy sinh viên"));
        }

        // Optional: link to a request
        Request linkedRequest = null;
        if (body.get("requestId") != null) {
            Integer requestId = ((Number) body.get("requestId")).intValue();
            linkedRequest = requestRepository.findById(requestId).orElse(null);
        }

        Report report = Report.builder()
                .student(student)
                .reportType(type)
                .title(title)
                .content(content)
                .request(linkedRequest)
                .status(Report.STATUS_NEW)
                .build();

        reportRepository.save(report);
        log.info("Student {} submitted feedback, ID: {}", mssv, report.getId());

        Map<String, Object> result = new HashMap<>();
        result.put("id", report.getId());
        result.put("title", report.getTitle());
        result.put("type", report.getReportType());
        result.put("status", report.getStatus());
        result.put("createdAt", report.getCreatedAt());

        return ResponseEntity.ok(ApiResponse.success(result, "Gửi góp ý thành công"));
    }

    @GetMapping("/feedback")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getFeedbackList(@RequestParam String mssv) {
        Student student = studentRepository.findByStudentId(mssv).orElse(null);
        if (student == null) {
            return ResponseEntity.status(404)
                    .body(ApiResponse.error("NOT_FOUND", "Không tìm thấy sinh viên"));
        }

        List<Report> reports = reportRepository.findByStudentId(mssv);
        List<Map<String, Object>> result = reports.stream().map(fb -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", fb.getId());
            map.put("type", fb.getReportType());
            map.put("title", fb.getTitle());
            map.put("content", fb.getContent());
            map.put("status", fb.getStatus());
            map.put("createdAt", fb.getCreatedAt());

            List<Reply> replies = replyRepository.findByReportId(fb.getId());
            if (!replies.isEmpty()) {
                map.put("reply", replies.get(0).getContent());
            }

            return map;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    // ==================== HELPER METHODS ====================

    private String getStatusName(Integer phase) {
        if (phase == null)
            return "---";
        return switch (phase) {
            case 0 -> "CANCELLED";
            case 1 -> "IN_QUEUE";
            case 2 -> "PENDING";
            case 3 -> "PROCESSING";
            case 4 -> "COMPLETED";
            case 5 -> "RECEIVED";
            case 6 -> "SUPPLEMENT";
            default -> "UNKNOWN";
        };
    }

    private String getQueueStatusName(int phase) {
        return switch (phase) {
            case 0 -> "CANCELLED";
            case 1, 2 -> "WAITING";
            case 3 -> "CALLED";
            case 4, 5 -> "COMPLETED";
            case 6 -> "SUPPLEMENT";
            default -> "UNKNOWN";
        };
    }

    private String getReportStatusName(int status) {
        return switch (status) {
            case 0 -> "PENDING";
            case 1 -> "PROCESSING";
            case 2 -> "RESOLVED";
            default -> "UNKNOWN";
        };
    }

    private String normalizeString(String s) {
        if (s == null)
            return "";
        String temp = Normalizer.normalize(s, Normalizer.Form.NFD);
        Pattern pattern = Pattern.compile("\\p{InCombiningDiacriticalMarks}+");
        return pattern.matcher(temp).replaceAll("").toLowerCase().trim();
    }
}











