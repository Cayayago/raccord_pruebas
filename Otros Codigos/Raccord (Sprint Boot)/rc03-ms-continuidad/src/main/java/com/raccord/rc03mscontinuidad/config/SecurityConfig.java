package com.raccord.rc03mscontinuidad.config;

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
                .requestMatchers("/api/guiones/test").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/guiones/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/escenas/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/desgloses/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/rodajes/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/guiones/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/guiones/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/guiones/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/escenas/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/escenas/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/escenas/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/desgloses/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/desgloses/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/desgloses/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.POST, "/api/rodajes/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PATCH, "/api/rodajes/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/rodajes/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .httpBasic(h -> {});
        return http.build();
    }
}
