package com.raccord.rc04msactores.repository;

import com.raccord.rc04msactores.entity.Personaje;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PersonajeRepository extends JpaRepository<Personaje, String> {
}
