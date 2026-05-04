package com.huit.pdt.web.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateUserRequest {

    @Size(max = 100, message = "Họ tên tối đa 100 ký tự")
    @JsonAlias({ "hoTen", "fullName" })
    private String hoTen;

    @Email(message = "Email không hợp lệ")
    @JsonAlias({ "email" })
    private String email;

    @Size(max = 15, message = "Số điện thoại tối đa 15 ký tự")
    @JsonAlias({ "soDienThoai", "phone" })
    private String soDienThoai;

    @Size(min = 6, message = "Mật khẩu ít nhất 6 ký tự")
    @JsonAlias({ "password" })
    private String password;

    @JsonAlias({ "roleId" })
    private Integer roleId;

    @JsonAlias({ "quayId", "counterId" })
    private Integer quayId;

    @JsonAlias({ "trangThai", "isActive" })
    private Boolean trangThai;
}










