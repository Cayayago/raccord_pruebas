package com.raccord.rc03mscontinuidad.service;

import com.raccord.rc03mscontinuidad.entity.Rodaje;
import com.raccord.rc03mscontinuidad.exception.RecursoNoEncontradoException;
import com.raccord.rc03mscontinuidad.repository.RodajeRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class RodajeService {

    private final RodajeRepository rodajeRepository;

    public RodajeService(RodajeRepository rodajeRepository) {
        this.rodajeRepository = rodajeRepository;
    }

    public List<Rodaje> listar() {
        return rodajeRepository.findAll();
    }

    public Rodaje buscarPorId(String id) {
        return rodajeRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Rodaje '" + id + "' no encontrado"));
    }

    public Rodaje guardar(Rodaje rodaje) {
        if (rodaje.getIdRodaje() == null || rodaje.getIdRodaje().trim().isEmpty())
            throw new IllegalArgumentException("El ID del rodaje es obligatorio");
        if (rodajeRepository.existsById(rodaje.getIdRodaje()))
            throw new IllegalArgumentException("Ya existe un rodaje con ID: " + rodaje.getIdRodaje());
        return rodajeRepository.save(rodaje);
    }

    public Rodaje actualizar(String id, Rodaje datos) {
        Rodaje existente = buscarPorId(id);
        if (datos.getVersion() != null) existente.setVersion(datos.getVersion());
        if (datos.getSemanaGrabacion() != null) existente.setSemanaGrabacion(datos.getSemanaGrabacion());
        if (datos.getDiaRodaje() != null) existente.setDiaRodaje(datos.getDiaRodaje());
        if (datos.getHoraInicio() != null) existente.setHoraInicio(datos.getHoraInicio());
        if (datos.getHoraFin() != null) existente.setHoraFin(datos.getHoraFin());
        if (datos.getLocation() != null) existente.setLocation(datos.getLocation());
        if (datos.getNotas() != null) existente.setNotas(datos.getNotas());
        if (datos.getActivo() != null) existente.setActivo(datos.getActivo());
        return rodajeRepository.save(existente);
    }

    public void eliminar(String id) {
        if (!rodajeRepository.existsById(id))
            throw new RecursoNoEncontradoException("Rodaje '" + id + "' no existe");
        rodajeRepository.deleteById(id);
    }
}
