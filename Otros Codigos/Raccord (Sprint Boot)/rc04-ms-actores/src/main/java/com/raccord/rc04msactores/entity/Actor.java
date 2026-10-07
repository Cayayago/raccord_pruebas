package com.raccord.rc04msactores.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDate;

@Entity
@Table(name = "actors")
public class Actor {

    @Id
    @Column(name = "id_actor", columnDefinition = "TEXT")
    private String idActor;  // ej: act1 — NO @GeneratedValue

    @NotBlank(message = "El nombre es obligatorio")
    @Column(name = "nombre", length = 45)
    private String nombre;

    @NotBlank(message = "El apellido es obligatorio")
    @Column(name = "apellido", length = 45)
    private String apellido;

    @Column(name = "nacionalidad", length = 50)
    private String nacionalidad;

    // Enum: generosex → masculino, femenino, otro
    @Column(name = "genero", columnDefinition = "generosex")
    private String genero;

    @Column(name = "fecha_de_nacimiento")
    private LocalDate fechaNacimiento;

    @Column(name = "talla_zapatos", length = 10)
    private String tallaZapatos;

    @Column(name = "ancho_espalda", length = 30)
    private String anchoDeEspalda;

    @Column(name = "pecho", length = 30)
    private String pecho;

    @Column(name = "cintura", length = 30)
    private String cintura;

    @Column(name = "cadera", length = 30)
    private String cadera;

    @Column(name = "largo_manga", length = 30)
    private String largoManga;

    @Column(name = "largo_pierna", length = 30)
    private String largoPierna;

    @Column(name = "talla_anillo", columnDefinition = "TEXT")
    private String tallaAnillo;

    @Column(name = "contorno_cabeza", length = 30)
    private String contornoCabeza;

    @Column(name = "contorno_cuello", length = 30)
    private String contornoCuello;

    @Column(name = "color_cabello", length = 45)
    private String colorCabello;

    @Column(name = "textura_cabello", length = 45)
    private String texturaCabello;

    @Column(name = "tipo_piel", length = 45)
    private String tipoPiel;

    @Column(name = "color_ojos", length = 45)
    private String colorOjos;

    @Column(name = "alergias", columnDefinition = "TEXT")
    private String alergias;

    @Column(name = "habilidades_especiales", columnDefinition = "TEXT")
    private String habilidadesEspeciales;

    @Column(name = "restricciones", columnDefinition = "TEXT")
    private String restricciones;

    @Column(name = "comentarios_adicionales", columnDefinition = "TEXT")
    private String comentariosAdicionales;

    @Column(name = "doble_riesgo")
    private Boolean dobleRiesgo;

    // FK → Personajes
    @Column(name = "id_personaje", columnDefinition = "TEXT")
    private String idPersonaje;

    public Actor() {}

    public String getIdActor() { return idActor; }
    public void setIdActor(String idActor) { this.idActor = idActor; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getApellido() { return apellido; }
    public void setApellido(String apellido) { this.apellido = apellido; }

    public String getNacionalidad() { return nacionalidad; }
    public void setNacionalidad(String nacionalidad) { this.nacionalidad = nacionalidad; }

    public String getGenero() { return genero; }
    public void setGenero(String genero) { this.genero = genero; }

    public LocalDate getFechaNacimiento() { return fechaNacimiento; }
    public void setFechaNacimiento(LocalDate fechaNacimiento) { this.fechaNacimiento = fechaNacimiento; }

    public String getTallaZapatos() { return tallaZapatos; }
    public void setTallaZapatos(String tallaZapatos) { this.tallaZapatos = tallaZapatos; }

    public String getAnchoDeEspalda() { return anchoDeEspalda; }
    public void setAnchoDeEspalda(String anchoDeEspalda) { this.anchoDeEspalda = anchoDeEspalda; }

    public String getPecho() { return pecho; }
    public void setPecho(String pecho) { this.pecho = pecho; }

    public String getCintura() { return cintura; }
    public void setCintura(String cintura) { this.cintura = cintura; }

    public String getCadera() { return cadera; }
    public void setCadera(String cadera) { this.cadera = cadera; }

    public String getLargoManga() { return largoManga; }
    public void setLargoManga(String largoManga) { this.largoManga = largoManga; }

    public String getLargoPierna() { return largoPierna; }
    public void setLargoPierna(String largoPierna) { this.largoPierna = largoPierna; }

    public String getTallaAnillo() { return tallaAnillo; }
    public void setTallaAnillo(String tallaAnillo) { this.tallaAnillo = tallaAnillo; }

    public String getContornoCabeza() { return contornoCabeza; }
    public void setContornoCabeza(String contornoCabeza) { this.contornoCabeza = contornoCabeza; }

    public String getContornoCuello() { return contornoCuello; }
    public void setContornoCuello(String contornoCuello) { this.contornoCuello = contornoCuello; }

    public String getColorCabello() { return colorCabello; }
    public void setColorCabello(String colorCabello) { this.colorCabello = colorCabello; }

    public String getTexturaCabello() { return texturaCabello; }
    public void setTexturaCabello(String texturaCabello) { this.texturaCabello = texturaCabello; }

    public String getTipoPiel() { return tipoPiel; }
    public void setTipoPiel(String tipoPiel) { this.tipoPiel = tipoPiel; }

    public String getColorOjos() { return colorOjos; }
    public void setColorOjos(String colorOjos) { this.colorOjos = colorOjos; }

    public String getAlergias() { return alergias; }
    public void setAlergias(String alergias) { this.alergias = alergias; }

    public String getHabilidadesEspeciales() { return habilidadesEspeciales; }
    public void setHabilidadesEspeciales(String habilidadesEspeciales) { this.habilidadesEspeciales = habilidadesEspeciales; }

    public String getRestricciones() { return restricciones; }
    public void setRestricciones(String restricciones) { this.restricciones = restricciones; }

    public String getComentariosAdicionales() { return comentariosAdicionales; }
    public void setComentariosAdicionales(String comentariosAdicionales) { this.comentariosAdicionales = comentariosAdicionales; }

    public Boolean getDobleRiesgo() { return dobleRiesgo; }
    public void setDobleRiesgo(Boolean dobleRiesgo) { this.dobleRiesgo = dobleRiesgo; }

    public String getIdPersonaje() { return idPersonaje; }
    public void setIdPersonaje(String idPersonaje) { this.idPersonaje = idPersonaje; }
}
