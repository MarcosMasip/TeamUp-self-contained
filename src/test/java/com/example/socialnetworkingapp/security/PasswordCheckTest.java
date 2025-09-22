package com.example.socialnetworkingapp.security;

import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.List;

/**
 * Helper test (not part of production) to verify seeded admin password hash
 * and to emit a fresh hash for the intended plaintext password (adminadmin).
 *
 * This lets us decide whether to adjust import.sql or README credentials.
 */
public class PasswordCheckTest {

    // Hash from first line of import.sql for admin@admin.com
    private static final String SEEDED_HASH = "$2a$10$QZ2GJNCiLgx8RhUEXUbWje5BGkBvHGOqLe7JtRVs8ZZm4hjlIBVDe";

    @Test
    void checkCandidatePasswords() {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        List<String> candidates = List.of(
                "adminadmin", "admin", "password", "admin123", "administrator", "Adminadmin"
        );
        System.out.println("Verifying which (if any) candidate matches the seeded hash...");
        for (String cand : candidates) {
            System.out.println(cand + " -> " + encoder.matches(cand, SEEDED_HASH));
        }
        System.out.println("Generated new bcrypt hash for 'adminadmin' (cost $2a$10):");
        System.out.println(encoder.encode("adminadmin"));
    }
}
