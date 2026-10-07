package com.raccord.rc03mscontinuidad.repository;

import com.raccord.rc03mscontinuidad.entity.Desglose;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DesgloseRepository extends JpaRepository<Desglose, String> {
}
