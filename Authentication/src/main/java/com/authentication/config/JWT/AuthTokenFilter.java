package com.authentication.config.jwt;

import java.io.IOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import com.authentication.service.UserAuthService;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class AuthTokenFilter extends OncePerRequestFilter{
    private final JwtUtils jwtUtils;

    private final UserAuthService userAuth;

    private static final Logger logger = LoggerFactory.getLogger(AuthTokenFilter.class);

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
        throws ServletException, IOException {
        try {
            String jwt = parseJwt(request);
            if (jwt != null) {
                logger.info("AuthTokenFilter: JWT found in request header.");
                if (jwtUtils.validateJwtToken(jwt)) {
                    logger.info("AuthTokenFilter: JWT is valid.");
                    String username = jwtUtils.getUserNameFromJwtToken(jwt);
                    logger.info("AuthTokenFilter: Username from JWT: {}", username);

                    UserDetails userDetails = userAuth.loadUserByUsername(username);
                    logger.info("AuthTokenFilter: UserDetails loaded for username: {}", userDetails.getUsername());

                    UsernamePasswordAuthenticationToken authentication =
                            new UsernamePasswordAuthenticationToken(
                                    userDetails,
                                    null, // Credentials (password) not needed as JWT is already validated
                                    userDetails.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                    logger.info("AuthTokenFilter: User '{}' authenticated and set in SecurityContext.", username);
                } else {
                    logger.warn("AuthTokenFilter: JWT validation failed.");
                }
            } else {
                logger.info("AuthTokenFilter: No JWT found in request header.");
            }
        } catch (io.jsonwebtoken.JwtException | IllegalArgumentException e) {
            logger.error("Cannot set user authentication: {}", e);
        }

        filterChain.doFilter(request, response);
    }

    private String parseJwt(HttpServletRequest request) {
        String headerAuth = request.getHeader("Authorization");
        logger.debug("AuthTokenFilter: Authorization header: {}", headerAuth);

        if (StringUtils.hasText(headerAuth) && headerAuth.startsWith("Bearer ")) {
            String token = headerAuth.substring(7);
            logger.debug("AuthTokenFilter: Extracted JWT: {}", token);
            return token;
        }

        logger.debug("AuthTokenFilter: Could not parse JWT from header.");
        return null;
    }
}
