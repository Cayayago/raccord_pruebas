package com.raccord.rc01msauth.repository;

import com.raccord.rc01msauth.entity.Departamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface DepartamentoRepository extends JpaRepository<Departamento, String> {
    Optional<Departamento> findByNombre(String nombre);
}
