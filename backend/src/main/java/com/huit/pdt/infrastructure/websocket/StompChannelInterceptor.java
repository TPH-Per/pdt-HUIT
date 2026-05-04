// infrastructure/websocket/StompChannelInterceptor.java

package com.huit.pdt.infrastructure.websocket;

import com.huit.pdt.infrastructure.security.JwtUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class StompChannelInterceptor implements ChannelInterceptor {
    @Autowired(required = false)
    private JwtUtils jwtUtils;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
            // Extract JWT token from STOMP CONNECT headers
            String authHeader = accessor.getFirstNativeHeader("Authorization");
            
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                String token = authHeader.substring(7);
                
                if (jwtUtils != null && jwtUtils.validateToken(token)) {
                    // Token is valid
                    String username = jwtUtils.getUsernameFromToken(token);
                    String role = jwtUtils.getRoleFromToken(token);
                    
                    log.debug("WebSocket STOMP user {} connected with role {}", username, role);
                } else {
                    log.warn("Invalid JWT token for WebSocket STOMP connection");
                }
            } else {
                log.warn("No JWT token in STOMP CONNECT headers");
            }
        }

        return message;
    }
}
