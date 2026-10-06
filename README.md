# Aula COIL · EPN

MVP de un aula virtual **COIL** (Collaborative Online International Learning) para conectar la Escuela Politécnica Nacional con una universidad socia.

**Enfoque:** *Moodle-first*. El aula COIL se arma con Moodle core (grupos, foros por grupo, tareas en grupo, rúbricas, finalización e insignias) y la universidad socia entra por LTI 1.3. No se escribe código propio en el piloto. El prototipo está hecho en HTML + CSS + JavaScript puro: sin frameworks, sin npm y sin build.

## Contenido

| Ruta | Qué es |
|---|---|
| [`docs/PROPUESTA-COIL-MVP.md`](docs/PROPUESTA-COIL-MVP.md) | Documento completo: **A** arquitectura y datos · **B** flujos UX y guía Figma · **C** prototipo · **D** integración Moodle/LMS · **E** checklist del piloto |
| [`prototipo/aula-coil.html`](prototipo/aula-coil.html) | Prototipo funcional en un solo archivo. Se abre con doble clic |
| [`db/schema.sql`](db/schema.sql) | Modelo de datos (12 tablas + vista de progreso), validado en PostgreSQL 16 |

## Enlaces

- Prototipo publicado (Claude Artifact, privado hasta que se comparta): https://claude.ai/artifact/NYM9FuZHDEZLkBAnv4Bnp3
- Diagramas en FigJam (modelo de datos, arquitecturas, flujos, secuencia LTI): https://www.figma.com/board/H4PMfd2USrRdSqSxnSOyY5

## Probar el prototipo

1. Abre `prototipo/aula-coil.html` en el navegador.
2. Usa **Ver como** para cambiar entre docente o estudiante, de la EPN o de la universidad socia.
3. Activa **Equivalencias Moodle** para ver qué módulo de Moodle implementa cada pantalla.
4. **Restablecer demo** vuelve a los datos de ejemplo (se guardan solo en tu navegador).

> Prototipo académico no oficial. "Partner University" es una institución ficticia de demostración.
