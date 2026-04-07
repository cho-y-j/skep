package com.skep.inspection.util;

import java.math.BigDecimal;

public class GpsUtil {

    private static final double EARTH_RADIUS_METERS = 6371000.0; // Earth's radius in meters
    private static final double MAX_INSPECTION_DISTANCE_METERS = 50.0; // 50 meters

    public static double calculateDistance(
        BigDecimal lat1, BigDecimal lng1,
        BigDecimal lat2, BigDecimal lng2
    ) {
        double lat1Rad = Math.toRadians(lat1.doubleValue());
        double lat2Rad = Math.toRadians(lat2.doubleValue());
        double deltaLat = Math.toRadians(lat2.doubleValue() - lat1.doubleValue());
        double deltaLng = Math.toRadians(lng2.doubleValue() - lng1.doubleValue());

        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
            Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_METERS * c;
    }

    public static boolean isWithinInspectionRange(
        BigDecimal inspectorLat, BigDecimal inspectorLng,
        BigDecimal equipmentLat, BigDecimal equipmentLng
    ) {
        double distance = calculateDistance(inspectorLat, inspectorLng, equipmentLat, equipmentLng);
        return distance <= MAX_INSPECTION_DISTANCE_METERS;
    }

    public static String getDistanceError(
        BigDecimal inspectorLat, BigDecimal inspectorLng,
        BigDecimal equipmentLat, BigDecimal equipmentLng
    ) {
        double distance = calculateDistance(inspectorLat, inspectorLng, equipmentLat, equipmentLng);
        return String.format(
            "Inspector is %.2f meters away from equipment (max allowed: %.2f meters)",
            distance,
            MAX_INSPECTION_DISTANCE_METERS
        );
    }
}
