package com.raccord.rc03mscontinuidad.repository;

import com.raccord.rc03mscontinuidad.entity.Escena;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface EscenaRepository extends JpaRepository<Escena, String> {
    List<Escena> findByIdGuion(Long idGuion);
    List<Escena> findByCiudad(String ciudad);
    List<Escena> findByMomentoDia(String momentoDia);
}
