package com.skep.auth.domain.enums;

public enum CompanyType {
    EQUIPMENT_SUPPLIER("Equipment Supplier"),
    BP_COMPANY("BP Company"),
    SAFETY_INSPECTION("Safety Inspection"),
    SITE_OWNER("Site Owner"),
    OTHER("Other");

    private final String displayName;

    CompanyType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public static CompanyType fromString(String type) {
        try {
            return CompanyType.valueOf(type.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid company type: " + type);
        }
    }
}
