package com.raccord.rc03mscontinuidad.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDate;


@Entity
@Table(name = "guiones")
public class Guion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_guion")
    private Integer idGuion;

    @NotBlank(message = "El nombre del guion es obligatorio")
    @Column(name = "nombre", length = 100)
    private String nombre;

    @Column(name = "numero_de_version", length = 45)
    private String numeroDeVersion;

    // Enum: estado_guion → Borrador, Revisión, Aprobado, En Rodaje, Archivado
    @Column(name = "estado", columnDefinition = "estado_guion")
    private String estado;

    @Column(name = "descripcion", columnDefinition = "TEXT")
    private String descripcion;

    @Column(name = "archivo", columnDefinition = "TEXT")
    private String archivo;

    @Column(name = "fecha_de_emision")
    private LocalDate fechaEmision;

    // FK → Project
    @Column(name = "id_project", columnDefinition = "TEXT")
    private String idProject;

    public Guion() {}

    public Integer getIdGuion() { return idGuion; }
    public void setIdGuion(Integer idGuion) { this.idGuion = idGuion; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getNumeroDeVersion() { return numeroDeVersion; }
    public void setNumeroDeVersion(String numeroDeVersion) { this.numeroDeVersion = numeroDeVersion; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public String getArchivo() { return archivo; }
    public void setArchivo(String archivo) { this.archivo = archivo; }

    public LocalDate getFechaEmision() { return fechaEmision; }
    public void setFechaEmision(LocalDate fechaEmision) { this.fechaEmision = fechaEmision; }

    public String getIdProject() { return idProject; }
    public void setIdProject(String idProject) { this.idProject = idProject; }
}
