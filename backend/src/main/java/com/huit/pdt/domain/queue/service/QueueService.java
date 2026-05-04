package com.huit.pdt.domain.queue.service;

import com.huit.pdt.domain.queue.dto.QueueTicketDTO;
import com.huit.pdt.domain.queue.dto.CreateQueueTicketRequest;
import java.util.List;
import java.util.Optional;

public interface QueueService {
    Optional<QueueTicketDTO> callNextTicket(Integer deskId, Integer registrarId);
    Optional<QueueTicketDTO> createTicket(CreateQueueTicketRequest request);
    Optional<QueueTicketDTO> updateTicketStatus(Long ticketId, String status, Integer registrarId);
    List<QueueTicketDTO> getActiveTickets(Integer deskId);
    Optional<QueueTicketDTO> getTicketById(Long ticketId);
    void cancelTicket(Long ticketId, String reason);
}
