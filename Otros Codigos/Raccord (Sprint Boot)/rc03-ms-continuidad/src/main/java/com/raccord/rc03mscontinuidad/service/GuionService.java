package com.raccord.rc03mscontinuidad.service;

import com.raccord.rc03mscontinuidad.entity.Guion;
import com.raccord.rc03mscontinuidad.exception.RecursoNoEncontradoException;
import com.raccord.rc03mscontinuidad.repository.GuionRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class GuionService {

    private final GuionRepository guionRepository;

    public GuionService(GuionRepository guionRepository) {
        this.guionRepository = guionRepository;
    }

    public List<Guion> listar() {
        return guionRepository.findAll();
    }

    public Guion buscarPorId(Long id) {
        return guionRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Guion con ID " + id + " no encontrado"));
    }

    public Guion guardar(Guion guion) {
        return guionRepository.save(guion);
    }

    public Guion actualizar(Long id, Guion datos) {
        Guion existente = buscarPorId(id);
        if (datos.getIdProject() != null) existente.setIdProject(datos.getIdProject());
        if (datos.getEstado() != null) existente.setEstado(datos.getEstado());
        return guionRepository.save(existente);
    }

    public void eliminar(Long id) {
        if (!guionRepository.existsById(id))
            throw new RecursoNoEncontradoException("Guion con ID " + id + " no encontrado");
        guionRepository.deleteById(id);
    }
}
