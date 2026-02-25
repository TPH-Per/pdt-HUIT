package com.example.demo.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * Enum chứa tất cả Error Codes của ứng dụng
 * 
 * Mỗi error code có:
 * - code: Mã lỗi (string) để frontend xử lý
 * - message: Thông báo mặc định (tiếng Việt)
 * - httpStatus: HTTP status code tương ứng
 * 
 * Lợi ích:
 * - Centralized: Tất cả lỗi ở 1 chỗ
 * - Consistent: Response format nhất quán
 * - Easy to maintain: Dễ thêm/sửa/xóa error codes
 */
@Getter
public enum ErrorCode {
    
    // ==================== AUTHENTICATION ERRORS (1xxx) ====================
    UNAUTHORIZED("AUTH_001", "Chưa đăng nhập hoặc phiên đăng nhập đã hết hạn", HttpStatus.UNAUTHORIZED),
    INVALID_CREDENTIALS("AUTH_002", "Mã nhân viên hoặc mật khẩu không đúng", HttpStatus.UNAUTHORIZED),
    ACCOUNT_DISABLED("AUTH_003", "Tài khoản đã bị khóa", HttpStatus.FORBIDDEN),
    TOKEN_EXPIRED("AUTH_004", "Token đã hết hạn", HttpStatus.UNAUTHORIZED),
    TOKEN_INVALID("AUTH_005", "Token không hợp lệ", HttpStatus.UNAUTHORIZED),
    ACCESS_DENIED("AUTH_006", "Không có quyền truy cập", HttpStatus.FORBIDDEN),
    
    // ==================== USER ERRORS (2xxx) ====================
    USER_NOT_FOUND("USER_001", "Không tìm thấy người dùng", HttpStatus.NOT_FOUND),
    USER_ALREADY_EXISTS("USER_002", "Người dùng đã tồn tại", HttpStatus.CONFLICT),
    EMAIL_ALREADY_EXISTS("USER_003", "Email đã được sử dụng", HttpStatus.CONFLICT),
    
    // ==================== VALIDATION ERRORS (3xxx) ====================
    VALIDATION_ERROR("VALID_001", "Dữ liệu không hợp lệ", HttpStatus.BAD_REQUEST),
    MISSING_REQUIRED_FIELD("VALID_002", "Thiếu trường bắt buộc", HttpStatus.BAD_REQUEST),
    INVALID_FORMAT("VALID_003", "Định dạng không hợp lệ", HttpStatus.BAD_REQUEST),
    
    // ==================== QUEUE/COUNTER ERRORS (4xxx) ====================
    QUEUE_NOT_FOUND("QUEUE_001", "Không tìm thấy hàng đợi", HttpStatus.NOT_FOUND),
    COUNTER_NOT_FOUND("COUNTER_001", "Không tìm thấy quầy", HttpStatus.NOT_FOUND),
    COUNTER_ALREADY_ASSIGNED("COUNTER_002", "Quầy đã được phân công cho nhân viên khác", HttpStatus.CONFLICT),
    
    // ==================== APPOINTMENT ERRORS (5xxx) ====================
    APPOINTMENT_NOT_FOUND("APPT_001", "Không tìm thấy lịch hẹn", HttpStatus.NOT_FOUND),
    APPOINTMENT_ALREADY_CANCELLED("APPT_002", "Lịch hẹn đã bị hủy", HttpStatus.BAD_REQUEST),
    APPOINTMENT_ALREADY_COMPLETED("APPT_003", "Lịch hẹn đã hoàn thành", HttpStatus.BAD_REQUEST),
    
    // ==================== PROCEDURE ERRORS (6xxx) ====================
    LOAITHUTUC_NOT_FOUND("PROC_001", "Không tìm thấy loại thủ tục", HttpStatus.NOT_FOUND),
    LOAITHUTUC_ALREADY_EXISTS("PROC_002", "Mã thủ tục đã tồn tại", HttpStatus.CONFLICT),
    CHUYENMON_NOT_FOUND("PROC_003", "Không tìm thấy chuyên môn", HttpStatus.NOT_FOUND),

    // ==================== SYSTEM ERRORS (9xxx) ====================
    INTERNAL_ERROR("SYS_001", "Lỗi hệ thống, vui lòng thử lại sau", HttpStatus.INTERNAL_SERVER_ERROR),
    DATABASE_ERROR("SYS_002", "Lỗi kết nối cơ sở dữ liệu", HttpStatus.INTERNAL_SERVER_ERROR),
    SERVICE_UNAVAILABLE("SYS_003", "Dịch vụ tạm thời không khả dụng", HttpStatus.SERVICE_UNAVAILABLE);
    
    private final String code;
    private final String message;
    private final HttpStatus httpStatus;
    
    ErrorCode(String code, String message, HttpStatus httpStatus) {
        this.code = code;
        this.message = message;
        this.httpStatus = httpStatus;
    }
}
