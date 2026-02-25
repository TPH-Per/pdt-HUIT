package com.example.demo.controller;

import com.example.demo.dto.response.ApiResponse;
import com.example.demo.dto.response.FeedbackResponse;
import com.example.demo.entity.Report;
import com.example.demo.entity.Reply;
import com.example.demo.entity.Registrar;
import com.example.demo.repository.ReportRepository;
import com.example.demo.repository.ReplyRepository;
import com.example.demo.repository.RegistrarRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Controller phản hồi sinh viên — Phòng Đào tạo
 */
@RestController
@RequestMapping("/api/registrar/feedbacks")
@RequiredArgsConstructor
@PreAuthorize("hasRole('Registrar') or hasRole('Admin')")
@Transactional
public class RegistrarFeedbackController {

        private final ReportRepository reportRepository;
        private final ReplyRepository replyRepository;
        private final RegistrarRepository registrarRepository;

        @GetMapping
        public ResponseEntity<ApiResponse<List<FeedbackResponse>>> getList(
                        @RequestParam(required = false) Integer status) {

                List<Report> reports;
                if (status != null) {
                        reports = reportRepository.findByStatus(status);
                } else {
                        reports = reportRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"));
                }

                List<FeedbackResponse> response = reports.stream()
                                .map(this::mapToResponse)
                                .collect(Collectors.toList());

                return ResponseEntity.ok(ApiResponse.success(response));
        }

        @GetMapping("/{id}")
        public ResponseEntity<ApiResponse<FeedbackResponse>> getDetail(@PathVariable Integer id) {
                Report report = reportRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Không tìm thấy phản ánh"));
                return ResponseEntity.ok(ApiResponse.success(mapToResponse(report)));
        }

        @PostMapping("/{id}/reply")
        public ResponseEntity<ApiResponse<FeedbackResponse>> reply(
                        @PathVariable Integer id,
                        @RequestBody Map<String, String> body,
                        Authentication authentication) {

                String content = body.get("content");
                if (content == null || content.isBlank()) {
                        return ResponseEntity.badRequest()
                                        .body(ApiResponse.error("EMPTY_CONTENT",
                                                        "Nội dung trả lời không được để trống"));
                }

                Registrar registrar = registrarRepository.findByRegistrarCode(authentication.getName())
                                .orElseThrow(() -> new RuntimeException("Không tìm thấy cán bộ đào tạo"));

                Report report = reportRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Không tìm thấy phản ánh"));

                Reply reply = Reply.builder()
                                .report(report)
                                .registrar(registrar)
                                .content(content)
                                .build();
                replyRepository.save(reply);

                if (report.getStatus() != Report.STATUS_RESOLVED) {
                        report.setStatus(Report.STATUS_RESOLVED);
                        reportRepository.save(report);
                }

                return ResponseEntity.ok(ApiResponse.success(mapToResponse(report), "Đã trả lời phản ánh"));
        }

        private FeedbackResponse mapToResponse(Report r) {
                List<Reply> replies = replyRepository.findByReportId(r.getId());

                List<FeedbackResponse.ReplyDto> replyDtos = replies.stream()
                                .map(re -> FeedbackResponse.ReplyDto.builder()
                                                .id(re.getId())
                                                .content(re.getContent())
                                                .registrarName(re.getRegistrar().getFullName())
                                                .createdAt(re.getCreatedAt())
                                                .build())
                                .collect(Collectors.toList());

                return FeedbackResponse.builder()
                                .id(r.getId())
                                .type(r.getReportType())
                                .title(r.getTitle())
                                .content(r.getContent())
                                .studentName(r.getStudent().getFullName())
                                .studentId(r.getStudent().getStudentId())
                                .requestCode(r.getRequest() != null ? r.getRequest().getRequestCode() : null)
                                .status(r.getStatus())
                                .createdAt(r.getCreatedAt())
                                .replies(replyDtos)
                                .build();
        }
}
