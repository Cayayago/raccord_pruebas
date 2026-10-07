package com.raccord.rc01msauth.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    // Usuarios en memoria: user (consulta) y admin (crea/elimina)
    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails user = User.withDefaultPasswordEncoder()
                .username("user").password("1234").roles("USER").build();
        UserDetails admin = User.withDefaultPasswordEncoder()
                .username("admin").password("Raccord2026*").roles("ADMIN").build();
        return new InMemoryUserDetailsManager(user, admin);
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                // Rutas públicas
                .requestMatchers("/api/auth/test").permitAll()
                .requestMatchers("/api/auth/login").permitAll()
                .requestMatchers("/api/auth/registro").permitAll()
                // USER y ADMIN pueden consultar
                .requestMatchers(HttpMethod.GET, "/api/auth/usuarios/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/usuarios/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/departamentos/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/roles/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/permisos/**").hasAnyRole("USER", "ADMIN")
                // Solo ADMIN puede crear, actualizar y eliminar
                .requestMatchers(HttpMethod.POST, "/api/auth/usuarios/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/auth/usuarios/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/usuarios/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/usuarios/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/usuarios/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/departamentos/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/departamentos/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/departamentos/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/roles/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/roles/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/roles/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/permisos/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/permisos/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/permisos/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .httpBasic(h -> {});
        return http.build();
    }
}
