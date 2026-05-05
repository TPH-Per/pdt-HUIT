package com.huit.pdt.domain.auth.service;

import lombok.RequiredArgsConstructor;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service("registrarUserDetailsService")
@RequiredArgsConstructor
public class RegistrarUserDetailsService implements UserDetailsService {
    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public UserDetails loadUserByUsername(String registrarCode) {
        String sql = """
            SELECT reg.registrar_code, reg.password_hash, reg.is_active,
                   r.role_name
            FROM registrar reg
            JOIN role r ON r.id = reg.role_id
            WHERE reg.registrar_code = :code
            """;
        try {
            return jdbc.queryForObject(sql, Map.of("code", registrarCode), (rs, n) ->
                User.builder()
                    .username(rs.getString("registrar_code"))
                    .password(rs.getString("password_hash"))
                    .disabled(!rs.getBoolean("is_active"))
                    .roles(rs.getString("role_name"))
                    .build());
        } catch (EmptyResultDataAccessException e) {
            throw new UsernameNotFoundException("Registrar not found: " + registrarCode);
        }
    }
}






