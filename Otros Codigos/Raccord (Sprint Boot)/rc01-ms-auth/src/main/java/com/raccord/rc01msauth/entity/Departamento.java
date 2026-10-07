package com.raccord.rc01msauth.entity;

import jakarta.persistence.*;

@Entity
@Table( name ="departamentos")

public class Departamento {
    @Id
    @Column (name ="id_departamento", columnDefinition ="TEXT")
    private String idDepartamento;

    @Column (name="nombre", length=45)
    private String nombre;

    @Column (name="ubicacion", columnDefinition="TEXT")
    private String ubicacion;

    public Departamento (){}

    public String getIdDepartamento() {return idDepartamento;}
    public void setIdDepartamento(String idDepartamento) {this.idDepartamento = idDepartamento;}

    public String getNombre() {return nombre;}
    public void setNombre(String nombre) {this.nombre = nombre;}

    public String getUbicacion() {return ubicacion;}
    public void setUbicacion(String ubicacion) {this.ubicacion = ubicacion;}
}
