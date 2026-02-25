package com.example.demo.controller;

import com.example.demo.dto.response.ApiResponse;
import com.example.demo.dto.response.HoSoResponse;
import com.example.demo.entity.Request;
import com.example.demo.entity.RequestHistory;
import com.example.demo.entity.Student;
import com.example.demo.entity.AcademicService;
import com.example.demo.entity.Registrar;
import com.example.demo.entity.Appointment;
import com.example.demo.repository.RequestHistoryRepository;
import com.example.demo.repository.RequestRepository;
import com.example.demo.repository.AppointmentRepository;
import com.example.demo.repository.StudentRepository;
import com.example.demo.repository.AcademicServiceRepository;
import com.example.demo.repository.RegistrarRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.text.Normalizer;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Controller quản lý yêu cầu — Phòng Đào tạo
 */
@RestController
@RequestMapping("/api/registrar/requests")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("hasRole('Registrar') or hasRole('Admin')")
@Transactional
public class RegistrarRequestController {

    private final RequestRepository requestRepository;
    private final RequestHistoryRepository requestHistoryRepository;
    private final AppointmentRepository appointmentRepository;
    private final RegistrarRepository registrarRepository;
    private final StudentRepository studentRepository;
    private final AcademicServiceRepository academicServiceRepository;

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<HoSoResponse.DashboardData>> getDashboard() {
        List<Request> allReqs = requestRepository.findAll();

        int choXuLy = 0, dangXuLy = 0, hoanThanh = 0, treHan = 0;
        LocalDate today = LocalDate.now();

        for (Request req : allReqs) {
            if (req.getCurrentPhase() == Request.PHASE_QUEUE ||
                    req.getCurrentPhase() == Request.PHASE_PENDING) {
                choXuLy++;
                if (req.getDeadline() != null && req.getDeadline().isBefore(today)) {
                    treHan++;
                }
            } else if (req.getCurrentPhase() == Request.PHASE_PROCESSING ||
                    req.getCurrentPhase() == Request.PHASE_RECEIVED) {
                dangXuLy++;
                if (req.getDeadline() != null && req.getDeadline().isBefore(today)) {
                    treHan++;
                }
            } else if (req.getCurrentPhase() == Request.PHASE_COMPLETED) {
                hoanThanh++;
            }
        }

        HoSoResponse.DashboardData dashboard = HoSoResponse.DashboardData.builder()
                .tongSoHoSo(allReqs.size())
                .choXuLy(choXuLy)
                .dangXuLy(dangXuLy)
                .hoanThanh(hoanThanh)
                .treHan(treHan)
                .build();

        return ResponseEntity.ok(ApiResponse.success(dashboard));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<HoSoResponse>>> getList(
            @RequestParam(required = false) Integer trangThai) {
        List<Request> reqs;

        if (trangThai != null) {
            int phase = mapTrangThaiToPhase(trangThai);
            reqs = requestRepository.findAll().stream()
                    .filter(a -> a.getCurrentPhase() == phase)
                    .collect(Collectors.toList());
        } else {
            reqs = requestRepository.findAll();
        }

        List<HoSoResponse> responses = reqs.stream()
                .map(this::mapToHoSoResponse)
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(responses));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<HoSoResponse>> getById(@PathVariable Integer id) {
        Request req = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu"));
        return ResponseEntity.ok(ApiResponse.success(mapToHoSoResponse(req)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<HoSoResponse>> create(
            @RequestBody Map<String, Object> body,
            Authentication authentication) {

        Registrar registrar = getCurrentRegistrar(authentication);

        String mssv = (String) body.get("mssv");
        String hoTen = (String) body.get("hoTen");
        String soDienThoai = (String) body.get("soDienThoai");
        String email = (String) body.get("email");
        Integer dichVuId = ((Number) body.get("dichVuId")).intValue();
        Integer doUuTien = body.get("doUuTien") != null
                ? ((Number) body.get("doUuTien")).intValue()
                : 0;
        Boolean confirmDuplicate = body.get("confirmDuplicate") != null
                ? (Boolean) body.get("confirmDuplicate")
                : false;

        Student student = studentRepository.findById(mssv).orElse(null);

        if (student != null) {
            String existName = normalizeString(student.getFullName());
            String newName = normalizeString(hoTen);

            if (!existName.equals(newName)) {
                if (!confirmDuplicate) {
                    return ResponseEntity.status(409).body(ApiResponse.error("STUDENT_CONFLICT",
                            "MSSV " + mssv + " đang thuộc về sinh viên: " + student.getFullName()
                                    + ". Bạn có muốn CẬP NHẬT tên mới (" + hoTen + ") cho sinh viên này không?"));
                } else {
                    student.setFullName(hoTen);
                    if (soDienThoai != null && !soDienThoai.isEmpty())
                        student.setPhone(soDienThoai);
                    if (email != null && !email.isEmpty())
                        student.setEmail(email);
                    student = studentRepository.save(student);
                    log.info("Overwrote student {} info. Old Name -> {}", mssv, hoTen);
                }
            } else {
                if (soDienThoai != null && !soDienThoai.isEmpty())
                    student.setPhone(soDienThoai);
                if (email != null && !email.isEmpty())
                    student.setEmail(email);
                student = studentRepository.save(student);
            }
        } else {
            student = Student.builder()
                    .studentId(mssv)
                    .fullName(hoTen)
                    .phone(soDienThoai)
                    .email(email)
                    .build();
            student = studentRepository.save(student);
        }

        AcademicService service = academicServiceRepository.findById(dichVuId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy dịch vụ"));

        String reqCode = "RQ" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Request req = Request.builder()
                .requestCode(reqCode)
                .student(student)
                .academicService(service)
                .currentPhase(Request.PHASE_PENDING)
                .priority(doUuTien)
                .deadline(LocalDate.now().plusDays(service.getProcessingDays()))
                .build();

        req = requestRepository.save(req);

        saveHistory(req, registrar, "TẠO YÊU CẦU",
                null, Request.PHASE_PENDING,
                "Tạo yêu cầu mới");

        log.info("Created request: {} by {}", req.getRequestCode(), registrar.getRegistrarCode());

        return ResponseEntity.ok(ApiResponse.success(mapToHoSoResponse(req), "Tạo yêu cầu thành công"));
    }

    @PostMapping("/from-appointment/{appointmentId}")
    public ResponseEntity<ApiResponse<HoSoResponse>> createFromAppointment(
            @PathVariable Integer appointmentId,
            Authentication authentication) {

        Registrar registrar = getCurrentRegistrar(authentication);
        Request req = requestRepository.findById(appointmentId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lịch hẹn"));

        req.setCurrentPhase(Request.PHASE_PENDING);
        req.setDeadline(LocalDate.now().plusDays(req.getAcademicService().getProcessingDays()));
        req = requestRepository.save(req);

        saveHistory(req, registrar, "TẠO YÊU CẦU TỪ LỊCH HẸN",
                Request.PHASE_COMPLETED, Request.PHASE_PENDING,
                "Tạo yêu cầu từ lịch hẹn " + req.getQueueDisplay());

        log.info("Created request from appointment: {} by {}", req.getRequestCode(), registrar.getRegistrarCode());

        return ResponseEntity.ok(ApiResponse.success(mapToHoSoResponse(req), "Tạo yêu cầu từ lịch hẹn thành công"));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<HoSoResponse>> updateStatus(
            @PathVariable Integer id,
            @RequestBody Map<String, Object> body,
            Authentication authentication) {

        Registrar registrar = getCurrentRegistrar(authentication);
        Request req = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu"));

        Integer trangThaiMoi = ((Number) body.get("trangThaiMoi")).intValue();
        String noiDung = (String) body.get("noiDung");
        String ngayHenStr = (String) body.get("ngayHen");
        String gioHenStr = (String) body.get("gioHen");

        int oldPhase = req.getCurrentPhase();
        int newPhase = mapTrangThaiToPhase(trangThaiMoi);
        LocalDate appointmentDate = null;
        LocalTime expectedTime = null;

        if (newPhase == Request.PHASE_SUPPLEMENT) {
            if (ngayHenStr == null || gioHenStr == null) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("MISSING_DATE_TIME", "Vui lòng chọn ngày và giờ hẹn bổ sung"));
            }
            appointmentDate = LocalDate.parse(ngayHenStr);
            expectedTime = LocalTime.parse(gioHenStr);

            Appointment appointment = Appointment.builder()
                    .request(req)
                    .registrar(registrar)
                    .appointmentDate(appointmentDate)
                    .appointmentTime(expectedTime)
                    .status(Appointment.STATUS_SCHEDULED)
                    .build();
            appointmentRepository.save(appointment);
        }

        req.setCurrentPhase(newPhase);
        req = requestRepository.save(req);

        if (newPhase == Request.PHASE_COMPLETED || newPhase == Request.PHASE_CANCELLED
                || newPhase == Request.PHASE_PROCESSING) {
            List<Appointment> apps = appointmentRepository.findActiveByRequestId(req.getId());
            for (Appointment a : apps) {
                a.setStatus(newPhase == Request.PHASE_CANCELLED ? Appointment.STATUS_CANCELLED
                        : Appointment.STATUS_COMPLETED);
                appointmentRepository.save(a);
            }
        }

        saveHistoryExtended(req, registrar, getActionByPhase(newPhase),
                oldPhase, newPhase,
                noiDung != null ? noiDung : HoSoResponse.getTrangThaiText(newPhase),
                appointmentDate, expectedTime);

        log.info("Updated request status: {} to {} by {}",
                req.getRequestCode(), newPhase, registrar.getRegistrarCode());

        return ResponseEntity.ok(ApiResponse.success(mapToHoSoResponse(req), "Cập nhật trạng thái thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<HoSoResponse>> update(
            @PathVariable Integer id,
            @RequestBody Map<String, Object> body,
            Authentication authentication) {

        Registrar registrar = getCurrentRegistrar(authentication);
        Request req = requestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu"));

        Student student = req.getStudent();
        if (body.get("hoTen") != null) {
            student.setFullName((String) body.get("hoTen"));
        }
        if (body.get("soDienThoai") != null) {
            student.setPhone((String) body.get("soDienThoai"));
        }
        studentRepository.save(student);

        if (body.get("doUuTien") != null) {
            req.setPriority(((Number) body.get("doUuTien")).intValue());
        }

        req = requestRepository.save(req);

        saveHistory(req, registrar, "CẬP NHẬT THÔNG TIN",
                req.getCurrentPhase(), req.getCurrentPhase(),
                "Cập nhật thông tin yêu cầu");

        log.info("Updated request: {} by {}", req.getRequestCode(), registrar.getRegistrarCode());

        return ResponseEntity.ok(ApiResponse.success(mapToHoSoResponse(req), "Cập nhật yêu cầu thành công"));
    }

    // ==================== HELPER METHODS ====================

    private Registrar getCurrentRegistrar(Authentication authentication) {
        String registrarCode = authentication.getName();
        return registrarRepository.findByRegistrarCode(registrarCode)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ đào tạo"));
    }

    private int mapTrangThaiToPhase(Integer trangThai) {
        return switch (trangThai) {
            case 0 -> Request.PHASE_CANCELLED;
            case 1 -> Request.PHASE_QUEUE;
            case 2 -> Request.PHASE_PENDING;
            case 3 -> Request.PHASE_PROCESSING;
            case 4 -> Request.PHASE_COMPLETED;
            case 5 -> Request.PHASE_RECEIVED;
            case 6 -> Request.PHASE_SUPPLEMENT;
            default -> Request.PHASE_PENDING;
        };
    }

    private String getActionByPhase(int phase) {
        if (phase == Request.PHASE_SUPPLEMENT)
            return "YÊU CẦU BỔ SUNG";
        if (phase == Request.PHASE_COMPLETED)
            return "HOÀN THÀNH";
        if (phase == Request.PHASE_PROCESSING)
            return "CHUYỂN GỌI SỐ";
        return "CẬP NHẬT TRẠNG THÁI";
    }

    private void saveHistoryExtended(Request req, Registrar registrar, String action,
            Integer oldPhase, int newPhase, String content,
            LocalDate date, LocalTime time) {
        RequestHistory history = RequestHistory.builder()
                .request(req)
                .serviceDesk(registrar.getServiceDesk())
                .registrar(registrar)
                .action(action)
                .phaseFrom(oldPhase)
                .phaseTo(newPhase)
                .content(content)
                .appointmentDate(date)
                .expectedTime(time)
                .createdAt(LocalDateTime.now())
                .build();
        requestHistoryRepository.save(history);
    }

    private void saveHistory(Request req, Registrar registrar, String action,
            Integer oldPhase, int newPhase, String content) {
        saveHistoryExtended(req, registrar, action, oldPhase, newPhase, content, null, null);
    }

    private HoSoResponse mapToHoSoResponse(Request req) {
        List<RequestHistory> histories = requestHistoryRepository.findByRequestId(req.getId());

        List<HoSoResponse.HistoryDto> historyDtos = histories.stream().map(h -> HoSoResponse.HistoryDto.builder()
                .nguoiXuLy(h.getRegistrar() != null ? h.getRegistrar().getFullName() : "Hệ thống")
                .hanhDong(h.getAction())
                .trangThaiCu(HoSoResponse.getTrangThaiText(h.getPhaseFrom()))
                .trangThaiMoi(HoSoResponse.getTrangThaiText(h.getPhaseTo()))
                .noiDung(h.getContent())
                .thoiGian(h.getCreatedAt())
                .build()).collect(Collectors.toList());

        return HoSoResponse.builder()
                .id(req.getId())
                .maHoSo(req.getRequestCode())
                .mssv(req.getStudent().getStudentId())
                .hoTenSinhVien(req.getStudent().getFullName())
                .soDienThoai(req.getStudent().getPhone())
                .email(req.getStudent().getEmail())
                .tenThuTuc(req.getAcademicService().getServiceName())
                .maThuTuc(req.getAcademicService().getServiceCode())
                .trangThai(req.getCurrentPhase())
                .trangThaiText(HoSoResponse.getTrangThaiText(req.getCurrentPhase()))
                .doUuTien(req.getPriority())
                .ngayNop(req.getCreatedAt())
                .hanXuLy(req.getDeadline())
                .nguonGoc("Trực tiếp")
                .maLichHen(req.getQueueDisplay())
                .loaiThuTucId(req.getAcademicService().getId())
                .thoiGianXuLyQuyDinh(req.getAcademicService().getProcessingDays())
                .lichSuXuLy(historyDtos)
                .build();
    }

    private String normalizeString(String s) {
        if (s == null)
            return "";
        String temp = Normalizer.normalize(s, Normalizer.Form.NFD);
        Pattern pattern = Pattern.compile("\\p{InCombiningDiacriticalMarks}+");
        return pattern.matcher(temp).replaceAll("").toLowerCase().trim();
    }
}
