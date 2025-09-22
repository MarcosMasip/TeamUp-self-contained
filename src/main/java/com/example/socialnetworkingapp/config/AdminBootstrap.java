package com.example.socialnetworkingapp.config;

import com.example.socialnetworkingapp.model.account.Account;
import com.example.socialnetworkingapp.model.account.AccountRepository;
import com.example.socialnetworkingapp.model.account.AccountRole;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(prefix = "app.admin.bootstrap", name = "enabled", havingValue = "true", matchIfMissing = true)
@RequiredArgsConstructor
public class AdminBootstrap implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminBootstrap.class);
    private final AccountRepository accountRepository;
    private final BCryptPasswordEncoder encoder;

    @Override
    public void run(String... args) {
        String email = "admin@admin.com";
        accountRepository.findAccountByEmail(email).ifPresentOrElse(acc -> {
            log.debug("[bootstrap] Admin account already present (id={})", acc.getId());
        }, () -> {
            log.info("[bootstrap] Creating missing admin account (property-controlled bootstrap) with email={} password=adminadmin", email);
            Account admin = new Account(AccountRole.ADMIN, "Admin", "Admin", email, encoder.encode("adminadmin"), "0000000000");
            accountRepository.save(admin);
        });
    }
}
