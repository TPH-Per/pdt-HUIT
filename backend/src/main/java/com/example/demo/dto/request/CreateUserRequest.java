package com.example.demo.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateUserRequest {

    @NotBlank(message = "Mã nhân viên không được để trống")
    @Size(max = 20, message = "Mã nhân viên tối đa 20 ký tự")
    @JsonAlias({ "maNhanVien", "staffCode" })
    private String maNhanVien;

    @NotBlank(message = "Họ tên không được để trống")
    @Size(max = 100, message = "Họ tên tối đa 100 ký tự")
    @JsonAlias({ "hoTen", "fullName" })
    private String hoTen;

    @Email(message = "Email không hợp lệ")
    @JsonAlias({ "email" })
    private String email;

    @Size(max = 15, message = "Số điện thoại tối đa 15 ký tự")
    @JsonAlias({ "soDienThoai", "phone" })
    private String soDienThoai;

    @NotBlank(message = "Mật khẩu không được để trống")
    @Size(min = 6, message = "Mật khẩu ít nhất 6 ký tự")
    @JsonAlias({ "password" })
    private String password;

    @NotNull(message = "Vai trò không được để trống")
    @JsonAlias({ "roleId" })
    private Integer roleId;

    @JsonAlias({ "quayId", "counterId" })
    private Integer quayId;
}
