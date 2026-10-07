package com.raccord.rc03mscontinuidad.entity;

import jakarta.persistence.*;
import lombok.extern.apachecommons.CommonsLog;

import java.time.LocalTime;

@Entity
@Table(name="desgloses")

public class Desglose {
    @Id
    @Column(name="id_desglose")
    private String idDesglose;

    @Column(name="version")
    private  String version;

    @Column(name="semana_grabacion")
    private Integer semanaGrabacion;

    @Column(name="dia_rodaje")
    private Integer diaRodaje;

    @Column(name="hora_inicio")
    private LocalTime horaInicio;

    @Column(name="hora_fin")
    private LocalTime horaFin;

    @Column(name="location")
    private String location;

    @Column(name="requerimientos")
    private String requerimientos;

    @Column(name="activo")
    private Boolean activo = true;

    public Desglose(){}

    public String getIdDesglose() {return idDesglose;}
    public void setIdDesglose(String idDesglose) {this.idDesglose = idDesglose;}

    public String getVersion() {return version;}
    public void setVersion(String version) {this.version = version;}

    public Integer getSemanaGrabacion() {return semanaGrabacion;}
    public void setSemanaGrabacion(Integer semanaGrabacion) {this.semanaGrabacion = semanaGrabacion;}

    public Integer getDiaRodaje() {return diaRodaje;}
    public void setDiaRodaje(Integer diaRodaje) {this.diaRodaje = diaRodaje;}

    public LocalTime getHoraInicio() {return horaInicio;}
    public void setHoraInicio(LocalTime horaInicio) {this.horaInicio = horaInicio;}

    public LocalTime getHoraFin() {return horaFin;}
    public void setHoraFin(LocalTime horaFin) {this.horaFin = horaFin;}

    public String getLocation() {return location;}
    public void setLocation(String location) {this.location = location;}

    public String getRequerimientos() {return requerimientos;}
    public void setRequerimientos(String requerimientos) {this.requerimientos = requerimientos;}

    public Boolean getActivo() {return activo;}
    public void setActivo(Boolean activo) {this.activo = activo;}

}