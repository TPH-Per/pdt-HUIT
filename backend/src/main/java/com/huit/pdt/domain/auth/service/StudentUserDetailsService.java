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

@Service("studentUserDetailsService")
@RequiredArgsConstructor
public class StudentUserDetailsService implements UserDetailsService {
    private final NamedParameterJdbcTemplate jdbc;

    @Override
    public UserDetails loadUserByUsername(String studentId) {
        String sql = """
            SELECT student_id, password_hash, is_active
            FROM student WHERE student_id = :id
            """;
        try {
            return jdbc.queryForObject(sql, Map.of("id", studentId), (rs, n) ->
                User.builder()
                    .username(rs.getString("student_id"))
                    .password(rs.getString("password_hash"))
                    .disabled(!rs.getBoolean("is_active"))
                    .roles("STUDENT")
                    .build());
        } catch (EmptyResultDataAccessException e) {
            throw new UsernameNotFoundException("Student not found: " + studentId);
        }
    }
}