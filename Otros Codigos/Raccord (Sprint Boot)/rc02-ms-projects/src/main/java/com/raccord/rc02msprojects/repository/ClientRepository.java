package com.raccord.rc02msprojects.repository;

import com.raccord.rc02msprojects.entity.Client;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface ClientRepository extends JpaRepository<Client, Long> {
    Optional<Client> findByEmail(String email);
    Optional<Client> findByDocument(String document);
    boolean existsByEmail(String email);
    boolean existsByDocument(String document);
}
