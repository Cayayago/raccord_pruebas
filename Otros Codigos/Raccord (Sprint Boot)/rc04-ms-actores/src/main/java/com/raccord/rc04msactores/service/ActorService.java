package com.raccord.rc04msactores.service;

import com.raccord.rc04msactores.entity.Actor;
import com.raccord.rc04msactores.exception.RecursoNoEncontradoException;
import com.raccord.rc04msactores.repository.ActorRepository;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class ActorService {

    private final ActorRepository actorRepository;

    public ActorService(ActorRepository actorRepository) {
        this.actorRepository = actorRepository;
    }

    public List<Actor> listar() {
        return actorRepository.findAll();
    }

    public Actor buscarPorId(String id) {
        return actorRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("Actor con ID '" + id + "' no encontrado"));
    }

    public Actor guardar(Actor actor) {
        if (actor.getIdActor() == null || actor.getIdActor().trim().isEmpty())
            throw new IllegalArgumentException("El ID del actor es obligatorio");
        if (actorRepository.existsById(actor.getIdActor()))
            throw new IllegalArgumentException("Ya existe un actor con ID: " + actor.getIdActor());
        if (actor.getNombre() == null || actor.getNombre().trim().isEmpty())
            throw new IllegalArgumentException("El nombre del actor es obligatorio");
        return actorRepository.save(actor);
    }

    public Actor actualizar(String id, Actor datos) {
        Actor existente = buscarPorId(id);
        if (datos.getNombre() != null) existente.setNombre(datos.getNombre());
        if (datos.getApellido() != null) existente.setApellido(datos.getApellido());
        if (datos.getNacionalidad() != null) existente.setNacionalidad(datos.getNacionalidad());
        if (datos.getGenero() != null) existente.setGenero(datos.getGenero());
        if (datos.getFechaNacimiento() != null) existente.setFechaNacimiento(datos.getFechaNacimiento());
        if (datos.getTallaZapatos() != null) existente.setTallaZapatos(datos.getTallaZapatos());
        if (datos.getAnchoDeEspalda() != null) existente.setAnchoDeEspalda(datos.getAnchoDeEspalda());
        if (datos.getPecho() != null) existente.setPecho(datos.getPecho());
        if (datos.getCintura() != null) existente.setCintura(datos.getCintura());
        if (datos.getCadera() != null) existente.setCadera(datos.getCadera());
        if (datos.getLargoManga() != null) existente.setLargoManga(datos.getLargoManga());
        if (datos.getLargoPierna() != null) existente.setLargoPierna(datos.getLargoPierna());
        if (datos.getTallaAnillo() != null) existente.setTallaAnillo(datos.getTallaAnillo());
        if (datos.getContornoCabeza() != null) existente.setContornoCabeza(datos.getContornoCabeza());
        if (datos.getContornoCuello() != null) existente.setContornoCuello(datos.getContornoCuello());
        if (datos.getColorCabello() != null) existente.setColorCabello(datos.getColorCabello());
        if (datos.getTexturaCabello() != null) existente.setTexturaCabello(datos.getTexturaCabello());
        if (datos.getTipoPiel() != null) existente.setTipoPiel(datos.getTipoPiel());
        if (datos.getColorOjos() != null) existente.setColorOjos(datos.getColorOjos());
        if (datos.getAlergias() != null) existente.setAlergias(datos.getAlergias());
        if (datos.getHabilidadesEspeciales() != null) existente.setHabilidadesEspeciales(datos.getHabilidadesEspeciales());
        if (datos.getRestricciones() != null) existente.setRestricciones(datos.getRestricciones());
        if (datos.getComentariosAdicionales() != null) existente.setComentariosAdicionales(datos.getComentariosAdicionales());
        if (datos.getDobleRiesgo() != null) existente.setDobleRiesgo(datos.getDobleRiesgo());
        if (datos.getIdPersonaje() != null) existente.setIdPersonaje(datos.getIdPersonaje());
        return actorRepository.save(existente);
    }

    public void eliminar(String id) {
        if (!actorRepository.existsById(id))
            throw new RecursoNoEncontradoException("Actor con ID '" + id + "' no existe");
        actorRepository.deleteById(id);
    }
}
