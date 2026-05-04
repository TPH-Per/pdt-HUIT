package com.huit.pdt.domain.servicedesk.service;

import com.huit.pdt.domain.servicedesk.dto.ServiceDeskDTO;
import com.huit.pdt.infrastructure.persistence.Registrar;
import com.huit.pdt.infrastructure.persistence.RegistrarRepository;
import com.huit.pdt.infrastructure.persistence.ServiceDesk;
import com.huit.pdt.infrastructure.persistence.ServiceDeskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ServiceDeskServiceImpl implements ServiceDeskService {

    private final ServiceDeskRepository serviceDeskRepository;
    private final RegistrarRepository registrarRepository;
    private final SimpMessagingTemplate ws;

    @Override
    public Optional<ServiceDeskDTO> openDesk(Integer deskId, Integer registrarId) {
        ServiceDesk desk = serviceDeskRepository.findById(deskId).orElse(null);
        if (desk == null) {
            log.warn("Desk {} not found", deskId);
            return Optional.empty();
        }

        Registrar registrar = registrarRepository.findById(registrarId).orElse(null);
        if (registrar == null) {
            log.warn("Registrar {} not found", registrarId);
            return Optional.empty();
        }

        desk.setRegistrar(registrar);
        desk.setIsActive(true);
        ServiceDesk saved = serviceDeskRepository.save(desk);

        ServiceDeskDTO dto = mapToDTO(saved);
        ws.convertAndSend("/topic/service-desks", dto);
        log.info("Opened desk {} by registrar {}", deskId, registrarId);
        return Optional.of(dto);
    }

    @Override
    public Optional<ServiceDeskDTO> closeDesk(Integer deskId, Integer registrarId) {
        ServiceDesk desk = serviceDeskRepository.findById(deskId).orElse(null);
        if (desk == null) {
            log.warn("Desk {} not found", deskId);
            return Optional.empty();
        }

        if (desk.getRegistrar() == null || !desk.getRegistrar().getId().equals(registrarId)) {
            log.warn("Registrar {} is not assigned to desk {}", registrarId, deskId);
            return Optional.empty();
        }

        desk.setRegistrar(null);
        desk.setIsActive(false);
        ServiceDesk saved = serviceDeskRepository.save(desk);

        ServiceDeskDTO dto = mapToDTO(saved);
        ws.convertAndSend("/topic/service-desks", dto);
        log.info("Closed desk {} by registrar {}", deskId, registrarId);
        return Optional.of(dto);
    }

    @Override
    public List<ServiceDeskDTO> getActiveDesks() {
        return serviceDeskRepository.findByIsActiveTrue().stream().map(this::mapToDTO).toList();
    }

    @Override
    public Optional<ServiceDeskDTO> getDeskById(Integer deskId) {
        return serviceDeskRepository.findById(deskId).map(this::mapToDTO);
    }

    @Override
    public List<ServiceDeskDTO> getDesksByCategory(Integer categoryId) {
        return serviceDeskRepository.findByServiceCategoryId(categoryId).stream().map(this::mapToDTO).toList();
    }

    private ServiceDeskDTO mapToDTO(ServiceDesk desk) {
        return new ServiceDeskDTO(
            desk.getId(),
            desk.getDeskCode(),
            desk.getDeskName(),
            desk.getServiceCategory() != null ? desk.getServiceCategory().getId() : null,
            desk.getRegistrar() != null ? desk.getRegistrar().getId() : null,
            desk.getRegistrar() != null ? desk.getRegistrar().getName() : null,
            desk.getIsActive(),
            null,
            null
        );
    }
}
