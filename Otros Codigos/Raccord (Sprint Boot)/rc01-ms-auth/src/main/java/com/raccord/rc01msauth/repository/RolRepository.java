package com.raccord.rc01msauth.repository;

import com.raccord.rc01msauth.entity.Rol;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface RolRepository extends JpaRepository<Rol, Integer> {
    Optional<Rol> findByNombre(String nombre);
    List<Rol> findByActivo(Boolean activo);
}
