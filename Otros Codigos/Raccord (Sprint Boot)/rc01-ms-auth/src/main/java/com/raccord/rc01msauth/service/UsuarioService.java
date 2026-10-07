package com.raccord.rc01msauth.service;

import com.raccord.rc01msauth.entity.Usuario;
import com.raccord.rc01msauth.exception.RecursoNoEncontradoException;
import com.raccord.rc01msauth.repository.UsuarioRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;

    public UsuarioService(UsuarioRepository usuarioRepository) {
        this.usuarioRepository = usuarioRepository;
    }

    public List<Usuario> listar() {
        return usuarioRepository.findAll();
    }

    public Usuario buscarPorId(Long id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Usuario con ID " + id + " no encontrado"));
    }

    public Usuario guardar(Usuario usuario) {
        if (usuario.getNombre() == null || usuario.getNombre().trim().isEmpty())
            throw new IllegalArgumentException("El nombre es obligatorio");
        if (usuario.getMail() == null || usuario.getMail().trim().isEmpty())
            throw new IllegalArgumentException("El mail es obligatorio");
        if (usuarioRepository.existsByMail(usuario.getMail()))
            throw new IllegalArgumentException("Ya existe un usuario con el mail: " + usuario.getMail());
        return usuarioRepository.save(usuario);
    }

    public Usuario actualizar(Long id, Usuario datos) {
        Usuario existente = buscarPorId(id);
        if (datos.getNombre() != null) existente.setNombre(datos.getNombre());
        if (datos.getApellido() != null) existente.setApellido(datos.getApellido());
        if (datos.getMsisdn() != null) existente.setMsisdn(datos.getMsisdn());
        if (datos.getDireccion() != null) existente.setDireccion(datos.getDireccion());
        if (datos.getEstado() != null) existente.setEstado(datos.getEstado());
        if (datos.getIdDepartamento() != null) existente.setIdDepartamento(datos.getIdDepartamento());
        if (datos.getIdRol() != null) existente.setIdRol(datos.getIdRol());
        if (datos.getIdProject() != null) existente.setIdProject(datos.getIdProject());
        return usuarioRepository.save(existente);
    }

    public void eliminar(Long id) {
        if (!usuarioRepository.existsById(id))
            throw new RecursoNoEncontradoException("Usuario con ID " + id + " no existe");
        usuarioRepository.deleteById(id);
    }
}
