package com.skep.equipmentservice.exception;

public class EquipmentException extends RuntimeException {

    public EquipmentException(String message) {
        super(message);
    }

    public EquipmentException(String message, Throwable cause) {
        super(message, cause);
    }
}
