package com.raccord.rc02msprojects.config;

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
                .requestMatchers("/api/projects/test").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/projects/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/clients/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/projects/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/projects/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/projects/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/clients/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/clients/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/clients/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .httpBasic(h -> {});
        return http.build();
    }
}
