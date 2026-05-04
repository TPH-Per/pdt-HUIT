package com.huit.pdt.domain.servicedesk.service;

import com.huit.pdt.domain.servicedesk.dto.ServiceDeskDTO;
import java.util.List;
import java.util.Optional;

public interface ServiceDeskService {
    Optional<ServiceDeskDTO> openDesk(Integer deskId, Integer registrarId);
    Optional<ServiceDeskDTO> closeDesk(Integer deskId, Integer registrarId);
    List<ServiceDeskDTO> getActiveDesks();
    Optional<ServiceDeskDTO> getDeskById(Integer deskId);
    List<ServiceDeskDTO> getDesksByCategory(Integer categoryId);
}
