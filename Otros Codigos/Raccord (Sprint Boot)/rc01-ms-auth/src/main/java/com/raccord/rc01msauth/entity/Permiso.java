package com.raccord.rc01msauth.entity;

import jakarta.persistence.*;

@Entity
@Table (name="permisos")

public class Permiso {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_permiso")
    private Integer idPermiso;

    @Column(name = "codigo", length = 50)
    private String codigo;

    @Column(name = "nombre", length = 100)
    private String nombre;

    @Column(name="modulo",length = 50)
    private String modulo;

    @Column(name="descripcion", columnDefinition = "TEXT")
    private String descripcion;

    @Column(name="activo")
    private boolean activo;

    public Permiso (){}

    public Integer getIdPermiso() {return idPermiso;}
    public void setIdPermiso(Integer idPermiso) {this.idPermiso = idPermiso;}

    public String getCodigo() {return codigo;}
    public void setCodigo(String codigo) {this.codigo = codigo;}

    public String getNombre() {return nombre;}
    public void setNombre(String nombre) {this.nombre = nombre;}

    public String getModulo() {return modulo;}
    public void setModulo(String modulo) {this.modulo = modulo;}

    public String getDescripcion() {return descripcion;}
    public void setDescripcion(String descripcion) {this.descripcion = descripcion;}

    public boolean getActivo() {return activo;}
    public void setActivo(boolean activo) {this.activo = activo;}
}
