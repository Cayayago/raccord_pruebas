package com.raccord.rc02msprojects.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;

@Entity
@Table(name = "projects")
public class Project {

    @Id
    @Column(name = "id_project", columnDefinition = "TEXT")
    private String idProject;  // ej: proj0001 — NO @GeneratedValue

    @NotBlank(message = "El nombre del proyecto es obligatorio")
    @Column(name = "project_name", length = 500)
    private String projectName;

    // Enum: formatos → serie, miniserie, pelicula, largometraje, etc.
    @Column(name = "formato_de_produccion")
    private String formatoProduccion;

    @Column(name = "sinopsis", columnDefinition = "TEXT")
    private String sinopsis;

    // Enum: generos → accion, comedia, drama, etc.
    @Column(name = "genero")
    private String genero;

    @Column(name = "director", length = 100)
    private String director;

    // FK → Client
    @Column(name = "id_client")
    private Integer idClient;

    public Project() {}

    public String getIdProject() { return idProject; }
    public void setIdProject(String idProject) { this.idProject = idProject; }

    public String getProjectName() { return projectName; }
    public void setProjectName(String projectName) { this.projectName = projectName; }

    public String getFormatoProduccion() { return formatoProduccion; }
    public void setFormatoProduccion(String formatoProduccion) { this.formatoProduccion = formatoProduccion; }

    public String getSinopsis() { return sinopsis; }
    public void setSinopsis(String sinopsis) { this.sinopsis = sinopsis; }

    public String getGenero() { return genero; }
    public void setGenero(String genero) { this.genero = genero; }

    public String getDirector() { return director; }
    public void setDirector(String director) { this.director = director; }

    public Integer getIdClient() { return idClient; }
    public void setIdClient(Integer idClient) { this.idClient = idClient; }
}
