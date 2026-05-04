// infrastructure/cache/CacheService.java

package com.huit.pdt.infrastructure.cache;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class CacheService {
    private final RedisTemplate<String, Object> redisTemplate;

    // Cache Keys
    private static final String SERVICE_CATEGORIES_KEY = "service:categories";
    private static final String QUEUE_STATS_PREFIX = "queue:stats:";
    private static final String STUDENT_PROFILE_PREFIX = "student:profile:";

    // TTL values (in minutes)
    private static final long CATEGORIES_TTL = 30;
    private static final long QUEUE_STATS_TTL = 5;
    private static final long STUDENT_PROFILE_TTL = 60;

    /**
     * Cache service categories (30 minutes)
     */
    public void cacheServiceCategories(Object categories) {
        redisTemplate.opsForValue().set(
            SERVICE_CATEGORIES_KEY,
            categories,
            CATEGORIES_TTL,
            TimeUnit.MINUTES
        );
    }

    public Object getServiceCategories() {
        return redisTemplate.opsForValue().get(SERVICE_CATEGORIES_KEY);
    }

    /**
     * Cache queue statistics (5 minutes)
     */
    public void cacheQueueStats(Integer queueId, Object stats) {
        String key = QUEUE_STATS_PREFIX + queueId;
        redisTemplate.opsForValue().set(
            key,
            stats,
            QUEUE_STATS_TTL,
            TimeUnit.MINUTES
        );
    }

    public Object getQueueStats(Integer queueId) {
        return redisTemplate.opsForValue().get(QUEUE_STATS_PREFIX + queueId);
    }

    /**
     * Invalidate queue cache
     */
    public void invalidateQueueStats(Integer queueId) {
        redisTemplate.delete(QUEUE_STATS_PREFIX + queueId);
    }

    /**
     * Cache student profile (60 minutes)
     */
    public void cacheStudentProfile(String studentId, Object profile) {
        String key = STUDENT_PROFILE_PREFIX + studentId;
        redisTemplate.opsForValue().set(
            key,
            profile,
            STUDENT_PROFILE_TTL,
            TimeUnit.MINUTES
        );
    }

    public Object getStudentProfile(String studentId) {
        return redisTemplate.opsForValue().get(STUDENT_PROFILE_PREFIX + studentId);
    }

    /**
     * Clear all cache
     */
    public void clearAll() {
        redisTemplate.getConnectionFactory().getConnection().flushAll();
    }

    /**
     * Generic cache operations
     */
    public void set(String key, Object value, long ttlMinutes) {
        redisTemplate.opsForValue().set(key, value, ttlMinutes, TimeUnit.MINUTES);
    }

    public Object get(String key) {
        return redisTemplate.opsForValue().get(key);
    }

    public void delete(String key) {
        redisTemplate.delete(key);
    }
}
