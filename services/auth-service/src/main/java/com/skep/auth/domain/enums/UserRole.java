package com.skep.auth.domain.enums;

public enum UserRole {
    PLATFORM_ADMIN("Platform Administrator"),
    EQUIPMENT_SUPPLIER("Equipment Supplier"),
    BP_COMPANY("BP Company"),
    SAFETY_INSPECTOR("Safety Inspector"),
    SITE_OWNER("Site Owner"),
    DRIVER("Driver"),
    GUIDE("Guide");

    private final String displayName;

    UserRole(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public static UserRole fromString(String role) {
        try {
            return UserRole.valueOf(role.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid role: " + role);
        }
    }
}
