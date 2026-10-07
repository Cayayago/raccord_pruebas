package com.raccord.rc03mscontinuidad.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDate;

@Entity
@Table(name = "escenas")
public class Escena {

    @Id
    @Column(name = "id_escena", columnDefinition = "TEXT")
    private String idEscena;  // ej: esc001 — NO @GeneratedValue

    @Column(name = "numero_de_escena", length = 100)
    private String numeroDEscena;

    @NotBlank(message = "El encabezado es obligatorio")
    @Column(name = "encabezado", columnDefinition = "TEXT")
    private String encabezado;

    @Column(name = "descripcion", columnDefinition = "TEXT")
    private String descripcion;

    // Enum: vistalugar → int, ext, int/ext, ext/int
    @Column(name = "modo_vista", columnDefinition = "vistalugar")
    private String modoVista;

    // Enum: momentodia → dia, noche, amanecer, atardecer, amanecer/dia, dia/noche
    @Column(name = "momento_dia", columnDefinition = "momentodia")
    private String momentoDia;

    @Column(name = "pagina")
    private Integer pagina;

    @Column(name = "ciudad", columnDefinition = "TEXT")
    private String ciudad;

    @Column(name = "fecha_de_grabacion")
    private LocalDate fechaGrabacion;

    @Column(name = "dia_dramatico")
    private Integer diaDramatico;

    // FK → Guion
    @Column(name = "id_guion")
    private Integer idGuion;

    // FK → Rodaje
    @Column(name = "id_rodaje", columnDefinition = "TEXT")
    private String idRodaje;

    // FK → Desglose
    @Column(name = "id_desglose", columnDefinition = "TEXT")
    private String idDesglose;

    public Escena() {}

    public String getIdEscena() { return idEscena; }
    public void setIdEscena(String idEscena) { this.idEscena = idEscena; }

    public String getNumeroDEscena() { return numeroDEscena; }
    public void setNumeroDEscena(String numeroDEscena) { this.numeroDEscena = numeroDEscena; }

    public String getEncabezado() { return encabezado; }
    public void setEncabezado(String encabezado) { this.encabezado = encabezado; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public String getModoVista() { return modoVista; }
    public void setModoVista(String modoVista) { this.modoVista = modoVista; }

    public String getMomentoDia() { return momentoDia; }
    public void setMomentoDia(String momentoDia) { this.momentoDia = momentoDia; }

    public Integer getPagina() { return pagina; }
    public void setPagina(Integer pagina) { this.pagina = pagina; }

    public String getCiudad() { return ciudad; }
    public void setCiudad(String ciudad) { this.ciudad = ciudad; }

    public LocalDate getFechaGrabacion() { return fechaGrabacion; }
    public void setFechaGrabacion(LocalDate fechaGrabacion) { this.fechaGrabacion = fechaGrabacion; }

    public Integer getDiaDramatico() { return diaDramatico; }
    public void setDiaDramatico(Integer diaDramatico) { this.diaDramatico = diaDramatico; }

    public Integer getIdGuion() { return idGuion; }
    public void setIdGuion(Integer idGuion) { this.idGuion = idGuion; }

    public String getIdRodaje() { return idRodaje; }
    public void setIdRodaje(String idRodaje) { this.idRodaje = idRodaje; }

    public String getIdDesglose() { return idDesglose; }
    public void setIdDesglose(String idDesglose) { this.idDesglose = idDesglose; }
}
