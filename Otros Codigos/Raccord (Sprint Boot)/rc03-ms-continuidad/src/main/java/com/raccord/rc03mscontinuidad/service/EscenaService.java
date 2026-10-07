package com.raccord.rc03mscontinuidad.service;

import com.raccord.rc03mscontinuidad.entity.Escena;
import com.raccord.rc03mscontinuidad.exception.RecursoNoEncontradoException;
import com.raccord.rc03mscontinuidad.repository.EscenaRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class EscenaService {

    private final EscenaRepository escenaRepository;

    public EscenaService(EscenaRepository escenaRepository) {
        this.escenaRepository = escenaRepository;
    }

    public List<Escena> listar() {
        return escenaRepository.findAll();
    }

    public Escena buscarPorId(String id) {
        return escenaRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Escena '" + id + "' no encontrada"));
    }

    public Escena guardar(Escena escena) {
        return escenaRepository.save(escena);
    }

    public Escena actualizar(String id, Escena datos) {
        Escena existente = buscarPorId(id);
        if (datos.getIdGuion() != null) existente.setIdGuion(datos.getIdGuion());
        if (datos.getCiudad() != null) existente.setCiudad(datos.getCiudad());
        if (datos.getMomentoDia() != null) existente.setMomentoDia(datos.getMomentoDia());
        return escenaRepository.save(existente);
    }

    public void eliminar(String id) {
        if (!escenaRepository.existsById(id))
            throw new RecursoNoEncontradoException("Escena '" + id + "' no encontrada");
        escenaRepository.deleteById(id);
    }
}
