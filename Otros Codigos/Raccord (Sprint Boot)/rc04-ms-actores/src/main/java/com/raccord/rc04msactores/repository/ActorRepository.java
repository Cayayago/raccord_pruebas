package com.raccord.rc04msactores.repository;

import com.raccord.rc04msactores.entity.Actor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ActorRepository extends JpaRepository<Actor, String> {
    List<Actor> findByNacionalidad(String nacionalidad);
    List<Actor> findByGenero(String genero);
    List<Actor> findByDobleRiesgo(Boolean dobleRiesgo);
}
