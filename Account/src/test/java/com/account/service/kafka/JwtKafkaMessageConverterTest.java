package com.account.service.kafka;

import org.apache.kafka.common.header.internals.RecordHeader;
import org.apache.kafka.common.header.internals.RecordHeaders;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import static org.mockito.Mockito.when;
import org.mockito.junit.jupiter.MockitoExtension;

import com.account.config.jwt.JwtUtils;
import com.account.config.kafka.JwtKafkaMessageConverter;

@ExtendWith(MockitoExtension.class)
class JwtKafkaMessageConverterTest {

    @Mock
    private JwtUtils jwtUtils;

    @InjectMocks
    private JwtKafkaMessageConverter jwtMessageConverter;

    @Test
    void testExtractJwtInfo_ValidToken() {
        // Arrange
        String validJwtToken = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
        RecordHeaders headers = new RecordHeaders();
        headers.add(new RecordHeader("Authorization", validJwtToken.getBytes()));

        when(jwtUtils.isTokenValid(validJwtToken)).thenReturn(true);
        when(jwtUtils.extractUsername(validJwtToken)).thenReturn("testuser");
        when(jwtUtils.extractRole(validJwtToken)).thenReturn("ROLE_USER");
        when(jwtUtils.extractCustomerId(validJwtToken)).thenReturn("customer123");

        // Act
        JwtKafkaMessageConverter.JwtInfo result = jwtMessageConverter.extractJwtInfo(headers);

        // Assert
        assertTrue(result.isValid());
        assertEquals("testuser", result.getUsername());
        assertEquals("ROLE_USER", result.getRole());
        assertEquals("customer123", result.getCustomerId());
        assertEquals(validJwtToken, result.getToken());
        assertNull(result.getError());
    }

    @Test
    void testExtractJwtInfo_InvalidToken() {
        // Arrange
        String invalidJwtToken = "Bearer invalid.jwt.token";
        RecordHeaders headers = new RecordHeaders();
        headers.add(new RecordHeader("Authorization", invalidJwtToken.getBytes()));

        when(jwtUtils.isTokenValid(invalidJwtToken)).thenReturn(false);

        // Act
        JwtKafkaMessageConverter.JwtInfo result = jwtMessageConverter.extractJwtInfo(headers);

        // Assert
        assertFalse(result.isValid());
        assertEquals(invalidJwtToken, result.getToken());
        assertEquals("Invalid JWT token", result.getError());
        assertNull(result.getUsername());
        assertNull(result.getRole());
        assertNull(result.getCustomerId());
    }

    @Test
    void testExtractJwtInfo_NoAuthorizationHeader() {
        // Arrange
        RecordHeaders headers = new RecordHeaders();

        // Act
        JwtKafkaMessageConverter.JwtInfo result = jwtMessageConverter.extractJwtInfo(headers);

        // Assert
        assertFalse(result.isValid());
        assertNull(result.getToken());
        assertEquals("No Authorization header found", result.getError());
        assertNull(result.getUsername());
        assertNull(result.getRole());
        assertNull(result.getCustomerId());
    }

    @Test
    void testCreateSecurityContext_ValidJwt() {
        // Arrange
        String validJwtToken = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
        JwtKafkaMessageConverter.JwtInfo jwtInfo = new JwtKafkaMessageConverter.JwtInfo(
            validJwtToken, "testuser", "ROLE_USER", "customer123", true, null
        );

        // Act
        var securityContext = jwtMessageConverter.createSecurityContext(jwtInfo);

        // Assert
        assertEquals(true, securityContext.get("authenticated"));
        assertEquals("testuser", securityContext.get("username"));
        assertEquals("ROLE_USER", securityContext.get("role"));
        assertEquals("customer123", securityContext.get("customerId"));
        assertEquals(validJwtToken, securityContext.get("jwtToken"));
    }

    @Test
    void testCreateSecurityContext_InvalidJwt() {
        // Arrange
        String invalidJwtToken = "Bearer invalid.jwt.token";
        JwtKafkaMessageConverter.JwtInfo jwtInfo = new JwtKafkaMessageConverter.JwtInfo(
            invalidJwtToken, null, null, null, false, "Invalid JWT token"
        );

        // Act
        var securityContext = jwtMessageConverter.createSecurityContext(jwtInfo);

        // Assert
        assertEquals(false, securityContext.get("authenticated"));
        assertEquals("Invalid JWT token", securityContext.get("error"));
        assertNull(securityContext.get("username"));
        assertNull(securityContext.get("role"));
        assertNull(securityContext.get("customerId"));
    }
}
