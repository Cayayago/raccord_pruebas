package com.raccord.rc03mscontinuidad.repository;

import com.raccord.rc03mscontinuidad.entity.Guion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface GuionRepository extends JpaRepository<Guion, Long> {
    List<Guion> findByIdProject(String idProject);
    List<Guion> findByEstado(String estado);
}
