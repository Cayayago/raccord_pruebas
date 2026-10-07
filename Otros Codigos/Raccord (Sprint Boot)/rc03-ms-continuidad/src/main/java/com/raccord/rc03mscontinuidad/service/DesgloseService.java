package com.raccord.rc03mscontinuidad.service;

import com.raccord.rc03mscontinuidad.entity.Desglose;
import com.raccord.rc03mscontinuidad.exception.RecursoNoEncontradoException;
import com.raccord.rc03mscontinuidad.repository.DesgloseRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class DesgloseService {

    private final DesgloseRepository desgloseRepository;

    public DesgloseService(DesgloseRepository desgloseRepository) {
        this.desgloseRepository = desgloseRepository;
    }

    public List<Desglose> listar() {
        return desgloseRepository.findAll();
    }

    public Desglose buscarPorId(String id) {
        return desgloseRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Desglose '" + id + "' no encontrado"));
    }

    public Desglose guardar(Desglose desglose) {
        if (desglose.getIdDesglose() == null || desglose.getIdDesglose().trim().isEmpty())
            throw new IllegalArgumentException("El ID del desglose es obligatorio");
        if (desgloseRepository.existsById(desglose.getIdDesglose()))
            throw new IllegalArgumentException("Ya existe un desglose con ID: " + desglose.getIdDesglose());
        return desgloseRepository.save(desglose);
    }

    public Desglose actualizar(String id, Desglose datos) {
        Desglose existente = buscarPorId(id);
        if (datos.getVersion() != null) existente.setVersion(datos.getVersion());
        if (datos.getSemanaGrabacion() != null) existente.setSemanaGrabacion(datos.getSemanaGrabacion());
        if (datos.getDiaRodaje() != null) existente.setDiaRodaje(datos.getDiaRodaje());
        if (datos.getHoraInicio() != null) existente.setHoraInicio(datos.getHoraInicio());
        if (datos.getHoraFin() != null) existente.setHoraFin(datos.getHoraFin());
        if (datos.getLocation() != null) existente.setLocation(datos.getLocation());
        if (datos.getRequerimientos() != null) existente.setRequerimientos(datos.getRequerimientos());
        if (datos.getActivo() != null) existente.setActivo(datos.getActivo());
        return desgloseRepository.save(existente);
    }

    public void eliminar(String id) {
        if (!desgloseRepository.existsById(id))
            throw new RecursoNoEncontradoException("Desglose '" + id + "' no existe");
        desgloseRepository.deleteById(id);
    }
}
