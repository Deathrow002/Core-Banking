package com.transaction.config.JWT;

import java.util.Collections;

import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.security.core.context.SecurityContextImpl;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.web.server.WebFilterChain;

import reactor.core.publisher.Mono;

@Component
public class AuthTokenWebFilter implements WebFilter {

    private final JwtUtils jwtUtils;

    public AuthTokenWebFilter(JwtUtils jwtUtils) {
        this.jwtUtils = jwtUtils;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (jwtUtils.isTokenValid(token)) {
                String username = jwtUtils.extractUsername(token);
                String role = jwtUtils.extractRole(token);
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(
                                username,
                                null,
                                Collections.singleton(() -> role)
                        );
                return chain.filter(exchange)
                        .contextWrite(ReactiveSecurityContextHolder.withSecurityContext(
                                Mono.just(new SecurityContextImpl(authentication))));
            }
        }
        return chain.filter(exchange);
    }
}