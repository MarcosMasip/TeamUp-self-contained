package com.example.socialnetworkingapp.mail;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

@Service
@Profile({"mock","local-h2"})
@Slf4j
public class LoggingMailService implements MailService {
    @Override
    public void send(String to, String subject, String body) {
        log.info("[MOCK MAIL] to='{}' subject='{}' body='{}'", to, subject, body == null ? "" : body.replaceAll("\n","\\n"));
    }
}
