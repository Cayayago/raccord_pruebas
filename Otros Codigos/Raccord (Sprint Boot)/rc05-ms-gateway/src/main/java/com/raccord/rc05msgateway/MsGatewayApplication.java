package com.raccord.rc05msgateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// ============================================================
// RC05 - API Gateway
// Punto de entrada único para todos los microservicios Raccord
//
// Flujo de una petición:
// Frontend → :8080 (Gateway) → rc01/:8081 | rc02/:8082 | rc03/:8083 | rc04/:8084
// ============================================================
@SpringBootApplication
public class MsGatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(MsGatewayApplication.class, args);
    }
}
