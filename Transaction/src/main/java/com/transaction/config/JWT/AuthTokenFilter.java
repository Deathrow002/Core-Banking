package com.transaction.config.jwt;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import io.jsonwebtoken.io.IOException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class AuthTokenFilter extends OncePerRequestFilter {
    private final JwtUtils jwtUtils;

    private static final Logger logger = LoggerFactory.getLogger(AuthTokenFilter.class);

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException, java.io.IOException {
        final String authHeader = request.getHeader("Authorization");

        String jwt = null;
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            jwt = authHeader.substring(7);
            logger.info("Authorization header: {}", authHeader);
            logger.info("Extracted JWT: {}", jwt);
        } else {
            logger.warn("No Bearer token found in Authorization header.");
        }

        if (jwt != null && jwtUtils.isTokenValid(jwt)) {
            logger.info("JWT is valid.");
            String username = jwtUtils.extractUsername(jwt);
            String role = jwtUtils.extractRole(jwt);
            String customerId = jwtUtils.extractCustomerId(jwt);

            logger.info("Extracted username: {}", username);
            logger.info("Extracted role: {}", role);
            logger.info("Extracted customerId: {}", customerId);

            String authorityRole = (role != null && role.startsWith("ROLE_")) ? role : "ROLE_" + role;
            List<SimpleGrantedAuthority> authorities = List.of(new SimpleGrantedAuthority(authorityRole));

            UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                    username, null, authorities);

            Map<String, Object> userDetails = new HashMap<>();
            userDetails.put("username", username);
            userDetails.put("customerId", customerId);
            userDetails.put("role", role);

            authToken.setDetails(userDetails);
            SecurityContextHolder.getContext().setAuthentication(authToken);
        } else if (jwt != null) {
            logger.warn("JWT is invalid or expired.");
        }

        chain.doFilter(request, response);
    }
}
