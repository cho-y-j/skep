package com.skep.inspection.service;

import com.skep.inspection.domain.InspectionItemMaster;
import com.skep.inspection.dto.CreateInspectionItemRequest;
import com.skep.inspection.repository.InspectionItemMasterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class InspectionItemMasterService {

    private final InspectionItemMasterRepository itemMasterRepository;

    public InspectionItemMaster createItem(UUID equipmentTypeId, CreateInspectionItemRequest request) {
        InspectionItemMaster item = InspectionItemMaster.builder()
            .equipmentTypeId(equipmentTypeId)
            .itemNumber(request.getItemNumber())
            .itemName(request.getItemName())
            .inspectionMethod(request.getInspectionMethod())
            .requiresPhoto(request.getRequiresPhoto() != null ? request.getRequiresPhoto() : true)
            .isActive(true)
            .sortOrder(request.getSortOrder())
            .build();

        return itemMasterRepository.save(item);
    }

    @Transactional(readOnly = true)
    public InspectionItemMaster getItemById(UUID id) {
        return itemMasterRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Inspection item not found: " + id));
    }

    @Transactional(readOnly = true)
    public List<InspectionItemMaster> getItemsByEquipmentType(UUID equipmentTypeId) {
        return itemMasterRepository.findActiveByEquipmentType(equipmentTypeId);
    }

    public InspectionItemMaster updateItem(UUID id, CreateInspectionItemRequest request) {
        InspectionItemMaster item = getItemById(id);
        item.setItemName(request.getItemName());
        item.setInspectionMethod(request.getInspectionMethod());
        if (request.getRequiresPhoto() != null) {
            item.setRequiresPhoto(request.getRequiresPhoto());
        }
        if (request.getSortOrder() != null) {
            item.setSortOrder(request.getSortOrder());
        }
        return itemMasterRepository.save(item);
    }

    public void deactivateItem(UUID id) {
        InspectionItemMaster item = getItemById(id);
        item.setIsActive(false);
        itemMasterRepository.save(item);
    }

    public void activateItem(UUID id) {
        InspectionItemMaster item = getItemById(id);
        item.setIsActive(true);
        itemMasterRepository.save(item);
    }

    @Transactional(readOnly = true)
    public List<InspectionItemMaster> getAllItems(UUID equipmentTypeId) {
        return itemMasterRepository.findByEquipmentTypeId(equipmentTypeId);
    }
}
