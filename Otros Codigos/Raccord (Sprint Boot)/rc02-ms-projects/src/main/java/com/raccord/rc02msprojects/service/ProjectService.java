package com.raccord.rc02msprojects.service;

import com.raccord.rc02msprojects.entity.Project;
import com.raccord.rc02msprojects.exception.RecursoNoEncontradoException;
import com.raccord.rc02msprojects.repository.ProjectRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class ProjectService {

    private final ProjectRepository projectRepository;

    public ProjectService(ProjectRepository projectRepository) {
        this.projectRepository = projectRepository;
    }

    public Project registrar(Project project) {
        if (project.getIdProject() == null || project.getIdProject().trim().isEmpty())
            throw new IllegalArgumentException("El ID del proyecto es obligatorio");
        if (projectRepository.existsById(project.getIdProject()))
            throw new IllegalArgumentException("Ya existe un proyecto con ID: " + project.getIdProject());
        return projectRepository.save(project);
    }

    public List<Project> listar() { return projectRepository.findAll(); }

    public Project buscarPorId(String id) {
        return projectRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Proyecto '" + id + "' no encontrado"));
    }

    public List<Project> buscarPorDirector(String director) { return projectRepository.findByDirector(director); }
    public List<Project> buscarPorGenero(String genero) { return projectRepository.findByGenero(genero); }

    public Project actualizar(String id, Project datos) {
        Project existente = buscarPorId(id);
        if (datos.getProjectName() != null) existente.setProjectName(datos.getProjectName());
        if (datos.getFormatoProduccion() != null) existente.setFormatoProduccion(datos.getFormatoProduccion());
        if (datos.getSinopsis() != null) existente.setSinopsis(datos.getSinopsis());
        if (datos.getGenero() != null) existente.setGenero(datos.getGenero());
        if (datos.getDirector() != null) existente.setDirector(datos.getDirector());
        if (datos.getIdClient() != null) existente.setIdClient(datos.getIdClient());
        return projectRepository.save(existente);
    }

    public void eliminar(String id) {
        if (!projectRepository.existsById(id))
            throw new RecursoNoEncontradoException("Proyecto '" + id + "' no existe");
        projectRepository.deleteById(id);
    }
}
