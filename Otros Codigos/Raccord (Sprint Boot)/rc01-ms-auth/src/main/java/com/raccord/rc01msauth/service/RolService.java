package com.raccord.rc01msauth.service;

import com.raccord.rc01msauth.entity.Rol;
import com.raccord.rc01msauth.exception.RecursoNoEncontradoException;
import com.raccord.rc01msauth.repository.RolRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class RolService {

    private final RolRepository rolRepository;

    public RolService(RolRepository rolRepository) {
        this.rolRepository = rolRepository;
    }

    public List<Rol> listar() {
        return rolRepository.findAll();
    }

    public Rol buscarPorId(Integer id) {
        return rolRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Rol con ID " + id + " no encontrado"));
    }

    public Rol guardar(Rol rol) {
        if (rol.getNombre() == null || rol.getNombre().trim().isEmpty())
            throw new IllegalArgumentException("El nombre del rol es obligatorio");
        return rolRepository.save(rol);
    }

    public Rol actualizar(Integer id, Rol datos) {
        Rol existente = buscarPorId(id);
        if (datos.getNombre() != null) existente.setNombre(datos.getNombre());
        if (datos.getNivelJerarquia() != null) existente.setNivelJerarquia(datos.getNivelJerarquia());
        if (datos.getDescripcion() != null) existente.setDescripcion(datos.getDescripcion());
        existente.setActivo(datos.getActivo());
        return rolRepository.save(existente);
    }

    public void eliminar(Integer id) {
        if (!rolRepository.existsById(id))
            throw new RecursoNoEncontradoException("Rol con ID " + id + " no existe");
        rolRepository.deleteById(id);
    }
}
