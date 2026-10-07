package com.raccord.rc01msauth.entity;
import jakarta.persistence.*;

@Entity
@Table(name="roles")
public class Rol {
    @Id
    @GeneratedValue (strategy = GenerationType.IDENTITY)
    @Column(name="id_rol")
    private Integer idRol;

    @Column(name="nombre", length =45)
    private String nombre;

    @Column(name="nivel_jerarquia", columnDefinition = "jerarquias_rol")
    private String nivelJerarquia;

    @Column(name = "descripcion", columnDefinition = "TEXT")
    private String descripcion;

    @Column(name = "activo")
    private boolean activo;

    public Rol(){}

    public Integer getIdRol() {return idRol;}
    public void setIdRol(Integer idRol) {this.idRol = idRol;}

    public String getNombre() {return nombre;}
    public void setNombre(String nombre) {this.nombre = nombre;}

    public String getNivelJerarquia() {return nivelJerarquia;}
    public void setNivelJerarquia(String nivelJerarquia) {this.nivelJerarquia = nivelJerarquia;}

    public String getDescripcion() {return descripcion;}
    public void setDescripcion(String descripcion) {this.descripcion = descripcion;}

    public boolean getActivo() {return activo;}
    public void setActivo(boolean activo) {this.activo = activo;}

}
