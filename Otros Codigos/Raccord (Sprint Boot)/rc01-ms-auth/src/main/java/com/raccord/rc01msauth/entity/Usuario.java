package com.raccord.rc01msauth.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.time.LocalDateTime;


@Entity
@Table(name = "users")
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_user")
    private Integer idUser;

    @NotBlank(message = "El nombre es obligatorio")
    @Column(name = "nombre", length = 50)
    private String nombre;

    @NotBlank(message = "El apellido es obligatorio")
    @Column(name = "apellido", length = 50)
    private String apellido;

    // Enum: tipo_documento → CC, TI, NIT, PA, CE
    @Column(name = "identificacion", columnDefinition = "tipo_documento")
    private String identificacion;

    @Column(name = "id_identificacion", columnDefinition = "TEXT")
    private String idIdentificacion;

    @Email(message = "El mail debe tener formato válido")
    @Column(name = "mail", columnDefinition = "TEXT")
    private String mail;

    @Column(name = "msisdn", columnDefinition = "TEXT")
    private String msisdn;

    @Column(name = "direccion", columnDefinition = "TEXT")
    private String direccion;

    @Column(name = "fecha_de_nacimiento")
    private LocalDate fechaNacimiento;

    // Enum: estado_usuario → activo, inactivo, pendiente, suspendido
    @Column(name = "estado", columnDefinition = "estado_usuario")
    private String estado;

    @Column(name = "fecha_de_creacion")
    private LocalDateTime fechaCreacion;

    @Column(name = "ultimo_acceso")
    private LocalDateTime ultimoAcceso;

    @NotBlank(message = "La contraseña es obligatoria")
    @Column(name = "contrasena", length = 500)
    private String contrasena;

    // FK → Departamento
    @Column(name = "id_departamento", columnDefinition = "TEXT")
    private String idDepartamento;

    // FK → Rol
    @Column(name = "id_rol")
    private Integer idRol;

    // FK → Project
    @Column(name = "id_project", columnDefinition = "TEXT")
    private String idProject;

    public Usuario() {}

    // Getters y Setters
    public Integer getIdUser() { return idUser; }
    public void setIdUser(Integer idUser) { this.idUser = idUser; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getApellido() { return apellido; }
    public void setApellido(String apellido) { this.apellido = apellido; }

    public String getIdentificacion() { return identificacion; }
    public void setIdentificacion(String identificacion) { this.identificacion = identificacion; }

    public String getIdIdentificacion() { return idIdentificacion; }
    public void setIdIdentificacion(String idIdentificacion) { this.idIdentificacion = idIdentificacion; }

    public String getMail() { return mail; }
    public void setMail(String mail) { this.mail = mail; }

    public String getMsisdn() { return msisdn; }
    public void setMsisdn(String msisdn) { this.msisdn = msisdn; }

    public String getDireccion() { return direccion; }
    public void setDireccion(String direccion) { this.direccion = direccion; }

    public LocalDate getFechaNacimiento() { return fechaNacimiento; }
    public void setFechaNacimiento(LocalDate fechaNacimiento) { this.fechaNacimiento = fechaNacimiento; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }

    public LocalDateTime getFechaCreacion() { return fechaCreacion; }
    public void setFechaCreacion(LocalDateTime fechaCreacion) { this.fechaCreacion = fechaCreacion; }

    public LocalDateTime getUltimoAcceso() { return ultimoAcceso; }
    public void setUltimoAcceso(LocalDateTime ultimoAcceso) { this.ultimoAcceso = ultimoAcceso; }

    public String getContrasena() { return contrasena; }
    public void setContrasena(String contrasena) { this.contrasena = contrasena; }

    public String getIdDepartamento() { return idDepartamento; }
    public void setIdDepartamento(String idDepartamento) { this.idDepartamento = idDepartamento; }

    public Integer getIdRol() { return idRol; }
    public void setIdRol(Integer idRol) { this.idRol = idRol; }

    public String getIdProject() { return idProject; }
    public void setIdProject(String idProject) { this.idProject = idProject; }
}
