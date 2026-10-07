package com.raccord.rc04msactores.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;


@Entity
@Table(name = "personajes")
public class Personaje {

    @Id
    @Column(name = "id_personaje", columnDefinition = "TEXT")
    private String idPersonaje;  // ej: cast1 — NO @GeneratedValue

    @Column(name = "codigo_personaje", length = 35)
    private String codigoPersonaje;

    @NotBlank(message = "El nombre del personaje es obligatorio")
    @Column(name = "nombre", length = 45)
    private String nombre;

    @Column(name = "edad")
    private Integer edad;

    public Personaje() {}

    public String getIdPersonaje() { return idPersonaje; }
    public void setIdPersonaje(String idPersonaje) { this.idPersonaje = idPersonaje; }

    public String getCodigoPersonaje() { return codigoPersonaje; }
    public void setCodigoPersonaje(String codigoPersonaje) { this.codigoPersonaje = codigoPersonaje; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public Integer getEdad() { return edad; }
    public void setEdad(Integer edad) { this.edad = edad; }
}
