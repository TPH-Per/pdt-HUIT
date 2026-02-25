package com.example.demo.dto.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class FeedbackResponse {
    private Integer id;
    private Integer type;
    private String title;
    private String content;
    private String studentName;
    private String studentId;
    private String requestCode;
    private Integer status;
    private LocalDateTime createdAt;
    private List<ReplyDto> replies;

    @Data
    @Builder
    public static class ReplyDto {
        private Integer id;
        private String content;
        private String registrarName;
        private LocalDateTime createdAt;
    }
}
