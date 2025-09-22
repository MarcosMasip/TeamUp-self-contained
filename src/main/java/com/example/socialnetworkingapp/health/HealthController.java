package com.example.socialnetworkingapp.health;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    // Context path is /api (see application.properties), so mapping should NOT repeat /api
    @GetMapping("/health")
    public ResponseEntity<?> health() {
        return ResponseEntity.ok().body(new Status("UP"));
    }

    static class Status {
        public final String status;
        Status(String s){this.status = s;}
        public String getStatus(){return status;}
    }
}
