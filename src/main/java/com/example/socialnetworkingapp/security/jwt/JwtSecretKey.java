package com.example.socialnetworkingapp.security.jwt;

import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

@Configuration
public class JwtSecretKey {
    private static final Logger log = LoggerFactory.getLogger(JwtSecretKey.class);
    private static final int MIN_BYTES = 32; // 256 bits for HS256
    private final JwtConfig jwtConfig;

    @Autowired
    public JwtSecretKey(JwtConfig jwtConfig){
        this.jwtConfig = jwtConfig;
    }

    @Bean
    public SecretKey getSecretKey(){
        String raw = jwtConfig.getSecretKey();
        if(raw == null) {
            log.warn("JWT secret is null; generating a new secure key.");
            return generateAndLog();
        }
        String trimmed = raw.trim();
        byte[] keyBytes = decodeIfBase64(trimmed);
        if(isWeak(trimmed, keyBytes)) {
            log.warn("Provided JWT secret is weak or placeholder (length={} bytes). Generating a secure ephemeral key.", keyBytes.length);
            return generateAndLog();
        }
        try {
            return Keys.hmacShaKeyFor(keyBytes);
        } catch (Exception e) {
            log.warn("Failed to use configured JWT secret ({}). Generating new secure key. Cause: {}", summarize(trimmed), e.getMessage());
            return generateAndLog();
        }
    }

    private SecretKey generateAndLog(){
        SecretKey key = Keys.secretKeyFor(SignatureAlgorithm.HS256);
        String base64 = Base64.getEncoder().encodeToString(key.getEncoded());
        log.warn("Ephemeral JWT key generated (Base64). For consistent signatures set APP_JWT_SECRET env var or application.jwt.secretKey to this value:\n{}", base64);
        return key;
    }

    private boolean isWeak(String original, byte[] keyBytes){
        if(keyBytes.length < MIN_BYTES) return true;
        String lower = original.toLowerCase();
        return lower.contains("default") || lower.contains("insecure") || lower.contains("change-me");
    }

    private byte[] decodeIfBase64(String value){
        if(value.matches("[A-Za-z0-9+/=]+") && value.length() % 4 == 0) {
            try {
                byte[] decoded = Base64.getDecoder().decode(value);
                if(decoded.length >= MIN_BYTES) return decoded;
            } catch (IllegalArgumentException ignored) { }
        }
        return value.getBytes(StandardCharsets.UTF_8);
    }

    private String summarize(String secret){
        if(secret.length() <= 12) return secret;
        return secret.substring(0,6) + "..." + secret.substring(secret.length()-4);
    }
}
