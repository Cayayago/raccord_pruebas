package com.raccord.rc02msprojects.repository;

import com.raccord.rc02msprojects.entity.Project;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ProjectRepository extends JpaRepository<Project, String> {
    List<Project> findByDirector(String director);
    List<Project> findByGenero(String genero);
}
