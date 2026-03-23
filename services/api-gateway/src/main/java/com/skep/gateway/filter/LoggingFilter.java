package com.skep.gateway.filter;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.Instant;

@Slf4j
@Component
public class LoggingFilter implements GlobalFilter, Ordered {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        long startTime = System.currentTimeMillis();
        String requestId = java.util.UUID.randomUUID().toString();

        exchange.getAttributes().put("requestId", requestId);

        return chain.filter(exchange).then(Mono.fromRunnable(() -> {
            long duration = System.currentTimeMillis() - startTime;
            String method = exchange.getRequest().getMethod().toString();
            String path = exchange.getRequest().getURI().getPath();
            int statusCode = exchange.getResponse().getStatusCode().value();

            log.info("REQUEST_LOG | RequestId: {} | Method: {} | Path: {} | Status: {} | Duration: {}ms",
                    requestId, method, path, statusCode, duration);
        }));
    }

    @Override
    public int getOrder() {
        return -1;
    }
}
