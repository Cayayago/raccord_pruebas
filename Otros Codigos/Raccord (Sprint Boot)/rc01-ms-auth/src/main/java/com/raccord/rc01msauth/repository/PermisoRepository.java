package com.raccord.rc01msauth.repository;

import com.raccord.rc01msauth.entity.Permiso;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface PermisoRepository extends JpaRepository<Permiso, Integer> {
    Optional<Permiso> findByCodigo(String codigo);
    List<Permiso> findByModulo(String modulo);
    List<Permiso> findByActivo(Boolean activo);
}
