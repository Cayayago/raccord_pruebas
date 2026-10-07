# Decisión de Arquitectura: Stack de Frontend para Raccord

**Fecha**: 1 de agosto de 2026
**Estado**: Aprobada

## Contexto

Raccord es una plataforma de continuidad para procesos audio-audiovisuales (seguimiento de continuidad en producciones). Los usuarios finales incluyen:

- Personal en set (mayoría): tablets y celulares (iOS y Android), con las manos ocupadas y poco tiempo entre tomas.
- Altos cargos: PC (Windows y Mac), con necesidad de más contexto visual y comparación de datos.

Requisitos técnicos principales:

- Acceso nativo a cámara (captura de fotos de continuidad).
- Acceso a galería del dispositivo.
- Acceso a documentos, incluyendo en PC.
- Sincronización offline de fotos: captura sin conexión en locaciones sin señal, subida automática al recuperar internet.
- Curva de aprendizaje baja: una sola experiencia de usuario consistente entre dispositivos.
- Backend ya definido: Python FastAPI (agnóstico del frontend elegido).
- Desarrollo de frontend existente: React + Vite, en etapa inicial (poco código escrito).

## Decisión

Migrar el desarrollo de frontend de React + Vite a Flutter, manteniendo FastAPI como backend sin cambios.

## Justificación

- **Cobertura de dispositivos**: Flutter compila desde un solo código base a iOS, Android, Windows y macOS, cubriendo exactamente el set de dispositivos de Raccord (tablets/celulares en set + PC de gestión), algo que React Web no resuelve de forma nativa sin herramientas adicionales (Electron/Tauri) ni con la misma calidad de acceso a hardware.
- **Acceso a cámara y galería**: Flutter ofrece plugins maduros y estables (camera, image_picker) con rendimiento cercano a nativo, crítico para el flujo de captura de fotos de continuidad en set.
- **Sincronización offline**: soporte robusto para colas locales (drift/Isar) y tareas en background (workmanager) que permiten capturar sin conexión y subir automáticamente al recuperar internet — más confiable que el manejo de background en navegadores/PWA.
- **Consistencia de UI = menor curva de aprendizaje**: una sola interfaz adaptativa (layouts responsivos) para tablet, celular y PC, evitando que el equipo tenga que aprender dos experiencias distintas.
- **Costo de migración bajo**: el desarrollo en React Vite está en etapa inicial, por lo que el cambio de stack no implica pérdida significativa de trabajo ya construido.
- **Backend sin impacto**: FastAPI expone una API REST/WebSocket agnóstica del cliente; no requiere cambios por este ajuste de frontend.

## Ingreso a la app (web → app nativa)

- Página web existente se mantiene como punto de entrada ("Ingresar").
- En PC: el enlace abre el flujo web normal en el navegador.
- En tablets/celulares: mediante Universal Links (iOS) / App Links (Android), el mismo enlace abre la app Flutter directamente si está instalada, sin pasar por el navegador.
- Requiere alojar `apple-app-site-association` (iOS) y `assetlinks.json` (Android) en el dominio.
- En Flutter, el enrutamiento de estos enlaces se maneja con el paquete `app_links`.
- Nota: Firebase Dynamic Links fue descontinuado por Google en agosto de 2025. No se usa. Al ser Raccord una herramienta de uso interno (no una app de consumo masivo con funnels de marketing), no se requiere deep linking diferido de terceros (Branch, AppsFlyer, etc.); Universal Links/App Links nativos son suficientes, con fallback a descarga desde la store si el usuario no tiene la app instalada.

## Alternativas consideradas y descartadas

- **Nativo (Swift/Kotlin por separado)**: máximo rendimiento pero duplica equipos, sin cobertura nativa de PC, riesgo de inconsistencia de UI entre plataformas.
- **React Native**: buen ecosistema pero soporte de escritorio (Windows/macOS) inmaduro, no resuelve el requisito de PC.
- **Ionic/Capacitor/PWA**: curva de desarrollo baja pero rendimiento insuficiente para app centrada en cámara/galería y manejo offline más frágil.
- **Kotlin Multiplatform (KMP)**: comparte lógica pero exige construir la UI por separado en cada plataforma, en contra del objetivo de una interfaz única y consistente.

## Impacto en la documentación del proyecto

A raíz de esta decisión se actualizó toda la documentación de requisitos, restricciones, sprints e historias de usuario que hacía referencia al stack anterior (React, React Native, Vite). Ver la sección correspondiente en `00_INFORME_DE_REVISION.md` para el detalle completo de los cambios realizados.
