package com.huit.pdt.infrastructure.security;

import com.huit.pdt.infrastructure.persistence.Registrar;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;

/**
 * Custom implementation of UserDetails interface
 * Hệ thống quản lý Phòng Đào tạo
 */
@Getter
public class CustomUserDetails implements UserDetails {

    private final Registrar registrar;

    public CustomUserDetails(Registrar registrar) {
        this.registrar = registrar;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        String roleName = registrar.getRole().getRoleName();
        return Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + roleName));
    }

    @Override
    public String getPassword() {
        return registrar.getPasswordHash();
    }

    @Override
    public String getUsername() {
        return registrar.getRegistrarCode();
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return registrar.getIsActive() != null && registrar.getIsActive();
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return registrar.getIsActive() != null && registrar.getIsActive();
    }

    public Integer getId() {
        return registrar.getId();
    }

    public String getFullName() {
        return registrar.getFullName();
    }

    public String getRoleName() {
        return registrar.getRole().getRoleName();
    }
}










