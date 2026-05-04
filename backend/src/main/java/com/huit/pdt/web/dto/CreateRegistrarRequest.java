package com.huit.pdt.web.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateRegistrarRequest {

    @NotBlank(message = "Mã cán bộ không được để trống")
    @Size(max = 20, message = "Mã cán bộ tối đa 20 ký tự")
    private String registrarCode;

    @NotBlank(message = "Họ tên không được để trống")
    @Size(max = 100, message = "Họ tên tối đa 100 ký tự")
    private String fullName;

    @Email(message = "Email không hợp lệ")
    private String email;

    @Size(max = 15, message = "Số điện thoại tối đa 15 ký tự")
    private String phone;

    @NotBlank(message = "Mật khẩu không được để trống")
    @Size(min = 6, message = "Mật khẩu ít nhất 6 ký tự")
    private String password;

    @NotNull(message = "Vai trò không được để trống")
    private Integer roleId;

    private Integer deskId;
}










