package com.example.demo.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateRegistrarRequest {

    @Size(max = 100, message = "Họ tên tối đa 100 ký tự")
    private String fullName;

    @Email(message = "Email không hợp lệ")
    private String email;

    @Size(max = 15, message = "Số điện thoại tối đa 15 ký tự")
    private String phone;

    @Size(min = 6, message = "Mật khẩu ít nhất 6 ký tự")
    private String password;

    private Integer roleId;

    private Integer deskId;

    private Boolean isActive;
}
