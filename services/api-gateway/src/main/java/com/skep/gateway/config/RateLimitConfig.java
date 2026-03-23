package com.skep.gateway.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.time.Duration;

@Slf4j
@Configuration
public class RateLimitConfig {

    private static final int MAX_REQUESTS = 100;
    private static final Duration WINDOW = Duration.ofMinutes(1);

    @Bean
    public GlobalFilter rateLimitFilter(ReactiveRedisTemplate<String, String> redisTemplate) {
        return (exchange, chain) -> {
            String clientId = resolveClientId(exchange);
            String key = "rate-limit:" + clientId;

            return redisTemplate.opsForValue()
                    .increment(key)
                    .flatMap(count -> {
                        if (count == 1) {
                            return redisTemplate.expire(key, WINDOW).thenReturn(1L);
                        }
                        return Mono.just(count);
                    })
                    .flatMap(count -> {
                        if (count > MAX_REQUESTS) {
                            log.warn("Rate limit exceeded for client: {}", clientId);
                            exchange.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
                            return exchange.getResponse().writeWith(
                                    Mono.just(exchange.getResponse().bufferFactory()
                                            .wrap("Rate limit exceeded".getBytes()))
                            );
                        }
                        return chain.filter(exchange);
                    });
        };
    }

    private String resolveClientId(ServerWebExchange exchange) {
        // IP 주소 기반 rate limiting
        String clientIp = exchange.getRequest().getRemoteAddress().getAddress().getHostAddress();
        String userId = exchange.getRequest().getHeaders().getFirst("X-User-Id");
        return userId != null ? userId : clientIp;
    }
}
