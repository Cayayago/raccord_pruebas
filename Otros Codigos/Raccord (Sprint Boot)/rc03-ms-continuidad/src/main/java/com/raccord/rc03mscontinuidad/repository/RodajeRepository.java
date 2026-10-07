package com.raccord.rc03mscontinuidad.repository;

import com.raccord.rc03mscontinuidad.entity.Rodaje;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RodajeRepository extends JpaRepository<Rodaje, String> {
}
