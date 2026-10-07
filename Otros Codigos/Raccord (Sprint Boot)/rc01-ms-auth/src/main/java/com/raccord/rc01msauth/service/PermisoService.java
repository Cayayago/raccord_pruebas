package com.raccord.rc01msauth.service;

import com.raccord.rc01msauth.entity.Permiso;
import com.raccord.rc01msauth.exception.RecursoNoEncontradoException;
import com.raccord.rc01msauth.repository.PermisoRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class PermisoService {

    private final PermisoRepository permisoRepository;

    public PermisoService(PermisoRepository permisoRepository) {
        this.permisoRepository = permisoRepository;
    }

    public List<Permiso> listar() {
        return permisoRepository.findAll();
    }

    public Permiso buscarPorId(Integer id) {
        return permisoRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Permiso con ID " + id + " no encontrado"));
    }

    public Permiso guardar(Permiso permiso) {
        if (permiso.getCodigo() == null || permiso.getCodigo().trim().isEmpty())
            throw new IllegalArgumentException("El código del permiso es obligatorio");
        if (permiso.getNombre() == null || permiso.getNombre().trim().isEmpty())
            throw new IllegalArgumentException("El nombre del permiso es obligatorio");
        return permisoRepository.save(permiso);
    }

    public Permiso actualizar(Integer id, Permiso datos) {
        Permiso existente = buscarPorId(id);
        if (datos.getCodigo() != null) existente.setCodigo(datos.getCodigo());
        if (datos.getNombre() != null) existente.setNombre(datos.getNombre());
        if (datos.getModulo() != null) existente.setModulo(datos.getModulo());
        if (datos.getDescripcion() != null) existente.setDescripcion(datos.getDescripcion());
        existente.setActivo(datos.getActivo());
        return permisoRepository.save(existente);
    }

    public void eliminar(Integer id) {
        if (!permisoRepository.existsById(id))
            throw new RecursoNoEncontradoException("Permiso con ID " + id + " no existe");
        permisoRepository.deleteById(id);
    }
}
