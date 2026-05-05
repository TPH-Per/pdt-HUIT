// infrastructure/ratelimit/RateLimitFilter.java

package com.huit.pdt.infrastructure.ratelimit;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class RateLimitFilter extends OncePerRequestFilter {
    private static final Map<String, Bucket> cache = new ConcurrentHashMap<>();

    // Rate limit buckets
    private static final Bandwidth LOGIN_LIMIT = Bandwidth.classic(5, Refill.intervally(5, Duration.ofMinutes(1)));
    private static final Bandwidth QUEUE_LIMIT = Bandwidth.classic(20, Refill.intervally(20, Duration.ofMinutes(1)));
    private static final Bandwidth DEFAULT_LIMIT = Bandwidth.classic(100, Refill.intervally(100, Duration.ofMinutes(1)));

    @PostConstruct
    void preInitializeBuckets() {
        cache.putIfAbsent("127.0.0.1:/api/auth/login", buildBucket(LOGIN_LIMIT));
        cache.putIfAbsent("0:0:0:0:0:0:0:1:/api/auth/login", buildBucket(LOGIN_LIMIT));
        cache.putIfAbsent("127.0.0.1:/api/registrar/queue", buildBucket(QUEUE_LIMIT));
        cache.putIfAbsent("0:0:0:0:0:0:0:1:/api/registrar/queue", buildBucket(QUEUE_LIMIT));
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        String path = request.getRequestURI();
        String clientIp = getClientIp(request);
        String bucketKey = clientIp + ":" + path;

        Bucket bucket = resolveBucket(clientIp, path);

        if (bucket.tryConsume(1)) {
            filterChain.doFilter(request, response);
        } else {
            response.addHeader("Retry-After", "60");
            response.setStatus(429);
            response.setContentType("application/json");
            response.getWriter().write("""
                    {"success":false,"code":"RATE_LIMITED","message":"Too many requests","data":null}
                    """);
            log.warn("Rate limit exceeded for {} on {}", clientIp, path);
        }
    }

    private Bucket resolveBucket(String clientIp, String path) {
        String bucketKey = clientIp + ":" + path;

        return cache.computeIfAbsent(bucketKey, k -> {
            Bandwidth bandwidth;
            
            if (path.contains("/auth/login")) {
                bandwidth = LOGIN_LIMIT;
            } else if (path.contains("/queue")) {
                bandwidth = QUEUE_LIMIT;
            } else {
                bandwidth = DEFAULT_LIMIT;
            }
            
            return buildBucket(bandwidth);
        });
    }

    private Bucket buildBucket(Bandwidth bandwidth) {
        return Bucket.builder()
                .addLimit(bandwidth)
                .build();
    }

    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }
        
        return request.getRemoteAddr();
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // Don't rate limit health checks and metrics
        String path = request.getRequestURI();
        return path.startsWith("/internal/actuator") || path.startsWith("/api/public");
    }
}
