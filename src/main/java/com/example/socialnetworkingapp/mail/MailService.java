package com.example.socialnetworkingapp.mail;

public interface MailService {
    void send(String to, String subject, String body);
}
