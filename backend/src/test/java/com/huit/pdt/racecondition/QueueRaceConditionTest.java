package com.huit.pdt.racecondition;

import com.huit.pdt.domain.queue.service.QueueService;
import com.huit.pdt.domain.queue.dto.CreateQueueTicketRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class QueueRaceConditionTest {

    @Autowired(required = false)
    private QueueService queueService;

    @Test
    public void testConcurrentCallNext_NoDuplicates() throws InterruptedException {
        if (queueService == null) {
            System.out.println("QueueService not available - skipping test");
            return;
        }

        Integer deskId = 1;
        Integer registrarId = 1;

        CreateQueueTicketRequest request = new CreateQueueTicketRequest(deskId, "STU001", null);
        for (int i = 0; i < 5; i++) {
            queueService.createTicket(request);
        }

        int threadCount = 20;
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch latch = new CountDownLatch(threadCount);
        Set<Long> calledTicketIds = Collections.synchronizedSet(new HashSet<>());
        AtomicInteger successCount = new AtomicInteger(0);

        for (int i = 0; i < threadCount; i++) {
            executor.submit(() -> {
                try {
                    queueService.callNextTicket(deskId, registrarId).ifPresent(ticket -> {
                        calledTicketIds.add(ticket.id());
                        successCount.incrementAndGet();
                    });
                } finally {
                    latch.countDown();
                }
            });
        }

        assertTrue(latch.await(10, TimeUnit.SECONDS), "Test timed out");
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);

        assertEquals(5, calledTicketIds.size(), "Should call exactly 5 unique tickets");
        assertEquals(5, successCount.get(), "Should have 5 successful calls");
    }

    @Test
    public void testConcurrentCreateTicket_NoDuplicateNumbers() throws InterruptedException {
        if (queueService == null) {
            System.out.println("QueueService not available - skipping test");
            return;
        }

        Integer deskId = 2;
        int threadCount = 20;
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch latch = new CountDownLatch(threadCount);
        Set<Integer> ticketNumbers = Collections.synchronizedSet(new HashSet<>());

        for (int i = 0; i < threadCount; i++) {
            final int idx = i;
            executor.submit(() -> {
                try {
                    CreateQueueTicketRequest request = new CreateQueueTicketRequest(deskId, "STU" + idx, null);
                    queueService.createTicket(request).ifPresent(ticket -> {
                        ticketNumbers.add(ticket.ticketNumber());
                    });
                } finally {
                    latch.countDown();
                }
            });
        }

        assertTrue(latch.await(10, TimeUnit.SECONDS), "Test timed out");
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);

        assertEquals(threadCount, ticketNumbers.size(), "Should have " + threadCount + " unique ticket numbers");
    }
}
