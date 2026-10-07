package com.raccord.rc04msactores.service;

import com.raccord.rc04msactores.entity.Personaje;
import com.raccord.rc04msactores.exception.RecursoNoEncontradoException;
import com.raccord.rc04msactores.repository.PersonajeRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class PersonajeService {

    private final PersonajeRepository personajeRepository;

    public PersonajeService(PersonajeRepository personajeRepository) {
        this.personajeRepository = personajeRepository;
    }

    public List<Personaje> listar() {
        return personajeRepository.findAll();
    }

    public Personaje buscarPorId(String id) {
        return personajeRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Personaje con ID '" + id + "' no encontrado"));
    }

    public Personaje guardar(Personaje personaje) {
        if (personaje.getIdPersonaje() == null || personaje.getIdPersonaje().trim().isEmpty())
            throw new IllegalArgumentException("El ID del personaje es obligatorio");
        if (personajeRepository.existsById(personaje.getIdPersonaje()))
            throw new IllegalArgumentException("Ya existe un personaje con ID: " + personaje.getIdPersonaje());
        if (personaje.getNombre() == null || personaje.getNombre().trim().isEmpty())
            throw new IllegalArgumentException("El nombre del personaje es obligatorio");
        return personajeRepository.save(personaje);
    }

    public Personaje actualizar(String id, Personaje datos) {
        Personaje existente = buscarPorId(id);
        if (datos.getCodigoPersonaje() != null) existente.setCodigoPersonaje(datos.getCodigoPersonaje());
        if (datos.getNombre() != null) existente.setNombre(datos.getNombre());
        if (datos.getEdad() != null) existente.setEdad(datos.getEdad());
        return personajeRepository.save(existente);
    }

    public void eliminar(String id) {
        if (!personajeRepository.existsById(id))
            throw new RecursoNoEncontradoException("Personaje con ID '" + id + "' no existe");
        personajeRepository.deleteById(id);
    }
}
