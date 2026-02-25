package com.example.demo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO returned when performing "Complete & Call Next" action
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompleteAndCallNextResponse {

    private RequestResponse completedRequest;
    private RequestResponse nextRequest;
    private String message;
    private boolean hasNext;
}
