package com.skep.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class GatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
    }

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("auth-service", r -> r
                        .path("/api/auth/**")
                        .uri("http://auth-service:8081"))
                .route("document-service", r -> r
                        .path("/api/documents/**")
                        .uri("http://document-service:8082"))
                .route("equipment-service", r -> r
                        .path("/api/equipment/**")
                        .uri("http://equipment-service:8083"))
                .route("dispatch-service", r -> r
                        .path("/api/dispatch/**")
                        .uri("http://dispatch-service:8084"))
                .route("inspection-service", r -> r
                        .path("/api/inspection/**")
                        .uri("http://inspection-service:8085"))
                .route("settlement-service", r -> r
                        .path("/api/settlement/**")
                        .uri("http://settlement-service:8086"))
                .route("notification-service", r -> r
                        .path("/api/notifications/**")
                        .uri("http://notification-service:8087"))
                .route("location-service", r -> r
                        .path("/api/location/**")
                        .uri("http://location-service:8088"))
                .build();
    }
}
