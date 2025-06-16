package com.account.config.JWT;

import java.security.Key;
import java.util.Date;
import java.util.function.Function;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class JwtUtils {
    private static final Logger logger = LoggerFactory.getLogger(JwtUtils.class);

    private final JwtConfig jwtConfig;

    private Key key() {
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(jwtConfig.getSecretKey()));
    }

    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                   .setSigningKey(key())
                   .build()
                   .parseClaimsJws(token)
                   .getBody();
    }

    public boolean isTokenValid(String token) {
        try {
            boolean expired = extractExpiration(token).before(new Date());
            logger.info("Token expired: {}", expired);
            return !expired;
        } catch (Exception e) {
            logger.error("Token validation error: {}", e.getMessage(), e);
            return false;
        }
    }

    public String extractUsername(String token) {
        try {
            String username = extractClaim(token, Claims::getSubject);
            logger.info("extractUsername: {}", username);
            return username;
        } catch (Exception e) {
            logger.error("Error extracting username: {}", e.getMessage(), e);
            return null;
        }
    }

    public String extractRole(String token) {
        try {
            String role = extractAllClaims(token).get("role", String.class);
            logger.info("extractRole: {}", role);
            return role;
        } catch (Exception e) {
            logger.error("Error extracting role: {}", e.getMessage(), e);
            return null;
        }
    }

    public String extractCustomerId(String token) {
        try {
            String customerId = extractAllClaims(token).get("customerId", String.class);
            logger.info("extractCustomerId: {}", customerId);
            return customerId;
        } catch (Exception e) {
            logger.error("Error extracting customerId: {}", e.getMessage(), e);
            return null;
        }
    }
}
