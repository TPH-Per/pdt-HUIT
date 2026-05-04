package com.huit.pdt.web.exception;

import lombok.Getter;

/**
 * Custom Exception cho ứng dụng
 * 
 * Dùng khi cần throw lỗi với ErrorCode cụ thể.
 * GlobalExceptionHandler sẽ catch và trả về ApiResponse với format chuẩn.
 * 
 * Ví dụ sử dụng:
 *   throw new AppException(ErrorCode.USER_NOT_FOUND);
 *   throw new AppException(ErrorCode.VALIDATION_ERROR, "Email không đúng định dạng");
 */
@Getter
public class AppException extends RuntimeException {
    
    private final ErrorCode errorCode;
    
    /**
     * Constructor với ErrorCode
     * Sử dụng message mặc định từ ErrorCode
     */
    public AppException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }
    
    /**
     * Constructor với ErrorCode và custom message
     * Override message mặc định
     */
    public AppException(ErrorCode errorCode, String customMessage) {
        super(customMessage);
        this.errorCode = errorCode;
    }
    
    /**
     * Constructor với ErrorCode và cause
     * Dùng khi wrap exception khác
     */
    public AppException(ErrorCode errorCode, Throwable cause) {
        super(errorCode.getMessage(), cause);
        this.errorCode = errorCode;
    }
}









