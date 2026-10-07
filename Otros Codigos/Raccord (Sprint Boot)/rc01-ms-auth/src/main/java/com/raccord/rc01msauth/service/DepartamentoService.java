package com.raccord.rc01msauth.service;

import com.raccord.rc01msauth.entity.Departamento;
import com.raccord.rc01msauth.exception.RecursoNoEncontradoException;
import com.raccord.rc01msauth.repository.DepartamentoRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class DepartamentoService {

    private final DepartamentoRepository departamentoRepository;

    public DepartamentoService(DepartamentoRepository departamentoRepository) {
        this.departamentoRepository = departamentoRepository;
    }

    public List<Departamento> listar() {
        return departamentoRepository.findAll();
    }

    public Departamento buscarPorId(String id) {
        return departamentoRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Departamento '" + id + "' no encontrado"));
    }

    public Departamento guardar(Departamento departamento) {
        if (departamento.getIdDepartamento() == null || departamento.getIdDepartamento().trim().isEmpty())
            throw new IllegalArgumentException("El ID del departamento es obligatorio");
        if (departamentoRepository.existsById(departamento.getIdDepartamento()))
            throw new IllegalArgumentException("Ya existe un departamento con ID: " + departamento.getIdDepartamento());
        return departamentoRepository.save(departamento);
    }

    public Departamento actualizar(String id, Departamento datos) {
        Departamento existente = buscarPorId(id);
        if (datos.getNombre() != null) existente.setNombre(datos.getNombre());
        if (datos.getUbicacion() != null) existente.setUbicacion(datos.getUbicacion());
        return departamentoRepository.save(existente);
    }

    public void eliminar(String id) {
        if (!departamentoRepository.existsById(id))
            throw new RecursoNoEncontradoException("Departamento '" + id + "' no existe");
        departamentoRepository.deleteById(id);
    }
}
