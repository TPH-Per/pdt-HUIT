package com.example.demo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO for queue dashboard at service desk
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QueueDashboardResponse {

    private Integer deskId;
    private String deskName;
    private String deskCode;

    private RequestResponse currentProcessing;
    private List<RequestResponse> waitingList;

    private Integer totalWaiting;
    private Integer totalCompleted;
    private Integer totalCancelled;
    private Integer averageProcessingTime;
}
