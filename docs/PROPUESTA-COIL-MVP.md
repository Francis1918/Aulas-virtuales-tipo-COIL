# Aula COIL · Propuesta de MVP

**Escuela Politécnica Nacional (EPN) + universidad socia**
Arquitectura, modelo de datos, flujos UX, prototipo e integración con Moodle

| Entregable | Dónde |
|---|---|
| Prototipo funcional (un solo archivo HTML) | [`prototipo/aula-coil.html`](../prototipo/aula-coil.html) · Artifact publicado (ver README) |
| Diagramas (modelo de datos, arquitecturas, flujos, secuencia LTI) | [Tablero FigJam](https://www.figma.com/board/H4PMfd2USrRdSqSxnSOyY5) |
| Esquema SQL validado en PostgreSQL 16 | [`db/schema.sql`](../db/schema.sql) |

---

## Decisión principal (léase primero)

El aula virtual actual de la EPN es un Moodle "de cursos": un profesor, sus estudiantes, clases y tareas.
Un aula **COIL** cambia cuatro cosas: **dos instituciones**, **equipos mixtos**, **dos idiomas y dos zonas horarias**, y un **ciclo de 4 fases** (conocerse → comparar → colaborar → presentar y reflexionar) con reflexión intercultural.

Ninguna de esas diferencias exige construir una plataforma desde cero. Por eso la recomendación es:

> **Ruta 1 (recomendada): "Moodle-first".** El Aula COIL es una **categoría de cursos en Moodle** con una **plantilla de curso COIL** y el estilo de la EPN. La universidad socia entra con **LTI 1.3**, que Moodle ya trae. No se escribe código propio en el piloto.
>
> **Ruta 2 (solo si no hay Moodle disponible):** una aplicación pequeña renderizada en servidor (PHP o Python con plantillas HTML), una sola base PostgreSQL y el modelo de [`db/schema.sql`](../db/schema.sql). Sin SPA ni frameworks de frontend.

**¿Por qué no React + Tailwind (u otra SPA)?** Para un piloto universitario cuesta más de lo que aporta: requiere un proceso de build, cientos de dependencias npm que cambian cada pocos meses y desarrolladores frontend especializados. Cuando el proyecto pase al equipo de TI o a otra cohorte de docentes, ese costo de mantenimiento es justo lo que provoca el abandono. El prototipo se hizo en **HTML + CSS + JavaScript puro**, en un solo archivo: se abre con doble clic, cualquiera lo puede leer y sirve de especificación visual para configurar Moodle.

---

## A. Arquitectura y modelo de datos minimalista

### A.1 Principios

1. **Configurar antes que programar.** Si Moodle core lo hace, no se programa.
2. **Una sola fuente de verdad por dato.** Las notas viven en el calificador de Moodle EPN; el LMS socio las recibe por LTI (AGS) y no las duplica a mano.
3. **UTC en la base, zona horaria en la persona.** Todas las fechas se guardan en UTC y se muestran en la zona de cada usuario (Moodle lo hace de forma nativa).
4. **Bilingüe por diseño, no por traducción completa.** La interfaz va en el idioma de cada usuario; el contenido clave (títulos, consignas) se escribe en ambos idiomas; lo demás se apoya con un botón "Traducir".
5. **Estándares abiertos en cada borde:** LTI 1.3 (acceso y notas), Open Badges (insignias), CSV/OneRoster (matrículas), Web Services REST (automatización).

### A.2 Ruta 1: Moodle-first (recomendada)

```
Estudiantes y docentes EPN ──HTTPS──┐
                                    ├──► Moodle EPN · categoría "Aula COIL" ──► BD Moodle + moodledata
LMS universidad socia ──LTI 1.3 ────┘          │
                                               ├─► Entra ID (login EPN)            [opcional]
                                               ├─► Zoom/Teams (mod_zoom o URL)     [opcional]
                                               ├─► Drive/OneDrive (repositorios)   [opcional]
                                               └─► LMS socio: NRPS (lista) y AGS (notas)
```
Diagrama editable: *"COIL MVP - Arquitectura Moodle-first (recomendada)"* en el [tablero FigJam](https://www.figma.com/board/H4PMfd2USrRdSqSxnSOyY5).

**Cómo se arma cada pieza del mapa conceptual con Moodle core** (es lo que muestra el botón *Equivalencias Moodle* del prototipo):

| Mapa conceptual | En Moodle (core salvo indicación) | Configuración clave |
|---|---|---|
| Aula virtual COIL | Curso dentro de la categoría **Aula COIL** | Plantilla `.mbz` con las 4 fases como secciones |
| Participantes | Matriculación manual o "Subir usuarios" (CSV) + **Publicar como herramienta LTI** | El socio entra por LTI 1.3; sin cuentas duplicadas |
| Equipos internacionales | **Grupos** + agrupamiento "Equipos COIL" | CSV con columna `group1`; regla: cada grupo mezcla ambas instituciones |
| Calendario | Calendario del curso | Zona horaria en el perfil de cada usuario |
| Materiales | Recurso URL, Archivo, Libro | Etiquetar idioma en el título `[ES]` / `[EN]` |
| Foros / interacción | Foro en modo **grupos separados** + foro general | Suscripción forzada para avisos |
| Actividades / Entregas | **Tarea** con "Los estudiantes envían en grupo" | Texto en línea + archivo o enlace |
| Reflexiones | Tarea de texto en línea sin calificación (o plugin *Journal*) | Una por fase, con pregunta guía bilingüe |
| Calificaciones | Calificador + **calificación avanzada: Rúbrica** | Rúbrica compartida, diseñada por ambos docentes |
| Progreso | **Finalización de actividad y de curso** | Requerir entrega o reflexión enviada |
| Badge / finalización | **Insignias** (compatibles con Open Badges) | Criterio: **calificación mínima del curso** (70 %); se emite automáticamente |
| Pesos por actividad (20/30/30/20) | Calificador con **categorías ponderadas** | Una categoría por actividad con su peso; el total del curso es la nota ponderada |
| Muro de videos (Padlet) | Actividad **Base de datos** con plantilla de galería, comentarios y valoraciones; o foro con enlaces | Un campo URL por video; comentarios habilitados; vista por grupo |
| Plan de colaboración (Word) | **Página o Libro** del curso, generado desde la plantilla | Se completa una vez por curso; la exportación a Word es opcional |
| Reporte con límite de palabras | **Tarea de texto en línea** con límite de palabras | Una tarea por sección o una sola con instrucciones por sección |
| Informe de evidencias | **Informes del curso** + exportar el Calificador a CSV/XLSX | Los videos y las capturas quedan como enlaces |
| Zoom / Teams | Plugin `mod_zoom` o actividad URL | Opcional |
| Google Drive | Repositorios Google Drive / OneDrive | Opcional |
| Bilingüe | Paquetes de idioma + filtro **Contenido multilenguaje** | `<span lang="es" class="multilang">` / `lang="en"` |

**Lo único "nuevo" que se produce:** una plantilla de curso, un tema visual alineado con la EPN (colores y tipografía del aula virtual actual) y una guía de una página para docentes. Todo eso lo mantiene el equipo que ya administra Moodle.

### A.3 Ruta 2: app propia ligera (alternativa)

Solo si no es posible usar Moodle EPN (políticas, versión antigua sin LTI 1.3, etc.).

- **Monolito con renderizado en servidor:** PHP 8 (mismo lenguaje que Moodle, conocido por TI) o Python/Django. Vistas HTML con plantillas; JavaScript mínimo, sin build.
- **Una base PostgreSQL** con [`db/schema.sql`](../db/schema.sql). Archivos en disco o en un bucket.
- **Login con OIDC** (Microsoft Entra ID para la EPN; Google o el IdP de la socia).
- **Módulo LTI 1.3 como herramienta**, para que más adelante Moodle u otro LMS la lancen (ver D).
- **Despliegue:** un contenedor + la base. Sin microservicios, colas ni Kubernetes.

### A.4 Modelo de datos mínimo (14 tablas)

Sirve para las dos rutas: en la Ruta 1 es el **modelo de dominio** (cada tabla corresponde a tablas de Moodle; ver comentarios `Moodle:` en el SQL); en la Ruta 2 es el **esquema real**.

```
institution 1─* person 1─* project_member *─1 project
                                 │                │
                          team *─┘ (team_id)      ├─* team
                                                  ├─* activity 1─* submission 1─* evaluation
                                                  ├─* resource
                                                  ├─* reflection (por persona y fase)
                                                  ├─* post (foro; team_id nulo = canal general)
                                                  └─* domain_event (outbox para integraciones)
```

| Tabla | Para qué | Decisión de diseño |
|---|---|---|
| `institution` | EPN y socia | Guarda zona horaria e idioma por defecto |
| `person` | Docentes y estudiantes | `external_ref` jsonb enlaza con Moodle/LTI sin tablas extra |
| `project` | El aula COIL | Título bilingüe en jsonb; enlaces opcionales a Zoom/Teams y Drive |
| `project_member` | Rol y equipo de cada persona | Rol por proyecto (no global); `badge_issued_at` evita una tabla de insignias |
| `team` | Equipos mixtos | Sin tabla intermedia: el equipo vive en `project_member.team_id` |
| `activity` | Entrega, reflexión o sesión | `phase` 1–4 y `kind` evitan tablas por tipo; `weight` (% de la nota), `wall` y `min_comments` para el muro; `template` para reportes por secciones; rúbrica en jsonb |
| `submission` | Entregas | Una fila por equipo o por persona (índices únicos parciales) |
| `evaluation` | Nota + rúbrica + retroalimentación | Separada de la entrega para permitir coevaluación más adelante |
| `comment`, `submission_like` | Comentarios y reacciones del muro | Cuelgan de `submission`; sirven también para exigir comentarios mínimos |
| `reflection` | Diario intercultural | Una por fase; visibilidad privada / docentes / equipo |
| `post` | Foro | `team_id` nulo = canal general; `lang` permite ofrecer "Traducir" |
| `resource` | Materiales | Enlaces con idioma |
| `domain_event` | Eventos para integraciones | Patrón *outbox*: base para webhooks y devolución de notas |

El **progreso** y la **nota ponderada** no se almacenan: se calculan (vistas `student_progress` y `student_grade`). Así no se desincronizan. El esquema tiene ahora 14 tablas y 2 vistas.

Diagrama ER editable: *"COIL MVP - Modelo de datos"* en el [tablero FigJam](https://www.figma.com/board/H4PMfd2USrRdSqSxnSOyY5).

---

## B. Flujos de experiencia de usuario y guía de prototipado en Figma

### B.1 Flujos indispensables

Diagrama editable: *"COIL MVP - Flujos de usuario"* en el tablero FigJam.

**Docente (EPN o socio), unos 15 minutos de preparación:**
1. Ingresa con su correo institucional.
2. Crea el proyecto COIL (título en dos idiomas, asignaturas de cada lado, fechas). Con la casilla *"Crear actividades base de las 4 fases"*, el aula nace con la estructura lista.
3. Carga estudiantes (CSV: nombre, correo, institución).
4. Pulsa **"Armar equipos mixtos"**: el sistema reparte por institución para que cada equipo mezcle ambas universidades y avisa si alguno queda sin mezcla.
5. Ajusta actividades y fechas (las escribe en su hora local; se guardan en UTC).
6. Califica con la **rúbrica compartida** desde una bandeja "Por calificar".
7. Revisa el progreso y emite la insignia.

**Estudiante internacional:**
1. Ingresa (EPN: correo institucional; socio: desde su propio LMS por LTI). La interfaz aparece en su idioma.
2. Ve sus proyectos, la fase actual y los próximos hitos **en su hora y en la de la otra universidad**.
3. En *Equipos* conoce a sus compañeros: institución, idioma, hora local y **mejor franja para reunirse** (calculada entre 08:00 y 20:00 de todas las zonas del equipo).
4. Conversa en el canal de su equipo; cada quien escribe en su idioma y usa "Traducir" cuando lo necesita.
5. Entrega (texto + enlace). En actividades de equipo, cualquier integrante entrega o actualiza.
6. Escribe su reflexión de la fase y elige quién la ve.
7. Revisa notas y retroalimentación, sigue su lista de actividades requeridas y recibe la insignia.

### B.2 Decisiones UX para una colaboración multicultural sin fricción

| Fricción típica en COIL | Respuesta en el diseño |
|---|---|
| "¿A qué hora es eso para mí?" | Cada fecha aparece doble: *dom 11 oct, 16:59 Quito · dom 23:59 Ámsterdam* |
| Equipos que nunca coinciden | Franja común calculada por equipo |
| Barrera de idioma | UI en el idioma de cada persona, títulos bilingües, botón "Traducir" (enlace a un traductor externo, sin API ni costo) |
| Estudiantes que no se animan a escribir | Guía de "buenas prácticas interculturales" junto al foro y reflexiones con visibilidad elegible |
| Docentes con poco tiempo | Plantilla de 4 fases, equipos automáticos y bandeja única de calificación |
| Conexiones lentas | Sin dependencias pesadas; las entregas por enlace evitan subir videos |
| Accesibilidad | Contraste AA, foco visible, navegación por teclado, sin depender del color para el estado |

### B.3 Guía de prototipado en Figma respetando el estilo EPN

**Tokens de diseño** (extraídos del aula virtual actual de la EPN; los mismos que usa el prototipo):

| Token | Valor | Uso |
|---|---|---|
| `navy` | `#1B2A4B` | Barra superior, botones primarios, chevrons de curso |
| `gold` | `#F2B632` | Acento: subtítulo de marca, fase actual, foco |
| `red` | `#C8432B` | Solo estados de atraso (color del escudo) |
| `bg` / `surface` | `#F5F6F9` / `#FFFFFF` | Fondo y tarjetas |
| `line` | `#DDE2EA` | Bordes de bloque (como "Course overview") |
| `muted` | `#5B6577` | Metadatos |
| Tipografía títulos | Roboto Slab 500 | Encabezados de bloque y nombres de curso en MAYÚSCULAS |
| Tipografía texto | Montserrat 400/600 | Navegación, cuerpo, botones |
| Radio | 6 px (botones), 2 px (tarjetas de curso) | Igual de sobrio que el aula actual |

**Estructura del archivo Figma** (una página por bloque):
1. `00 Fundamentos`: estilos de color y texto con los tokens anteriores (crear como *Variables* con modo claro y oscuro).
2. `01 Componentes`: barra superior, tarjeta de proyecto (chevron + metadatos + título + barra de progreso + estado), ítem de actividad (icono por tipo, fechas dobles, estado), tarjeta de miembro (avatar con color por institución), *pill* de estado, *chip* de institución, botón primario y secundario.
3. `02 Pantallas escritorio (1280)`: Panel, Proyecto › Actividades, Equipos, Foro, Reflexiones, Calificaciones (docente), Progreso e insignia (estudiante), Calendario, modal "Nuevo proyecto".
4. `03 Pantallas móvil (390)`.
5. `04 Flujos`: conexiones de prototipo entre pantallas siguiendo B.1.

**Atajo para no dibujar desde cero:** abrir `prototipo/aula-coil.html` en el navegador y capturarlo con la extensión de Chrome de Figma (o el plugin *html.to.design*). Cada vista queda como capas editables; luego se reemplazan por componentes de `01 Componentes`. Los diagramas de arquitectura, datos y flujos ya están en el [tablero FigJam](https://www.figma.com/board/H4PMfd2USrRdSqSxnSOyY5).

**No usar** el escudo ni el lema institucional en el prototipo hasta tener aprobación de Comunicación de la EPN. El prototipo usa una marca neutra ("Aula COIL", dos anillos entrelazados) con los colores institucionales.

---

## C. Prototipo interactivo (HTML + CSS + JavaScript, publicable como Claude Artifact)

**Archivo:** [`prototipo/aula-coil.html`](../prototipo/aula-coil.html), unas 900 líneas, sin dependencias (solo Google Fonts).

**Cómo usarlo**
- **Local:** doble clic en el archivo. No requiere instalar nada.
- **Claude Artifact:** ya está publicado (enlace en el README). Para iterar, se pega el archivo en una conversación con Claude y se pide el cambio.
- **Figma:** ver el atajo en B.3.

**Qué se puede probar** (con el selector *Ver como*):

| Como… | Prueba |
|---|---|
| Francis Bravo (estudiante EPN) | Panel, **muro de videos** (le falta comentar a un compañero), entrega de equipo con **reporte por secciones y contador de palabras**, **nota ponderada con meta del 70 %**, insignia bloqueada |
| Valeria Ortiz (estudiante de la universidad socia) | Lo mismo desde el otro lado, con hora de Chihuahua; cambia a inglés con el botón EN |
| María Cevallos (docente EPN) | Crear proyecto con plantilla (pesos 20/30/30/20), cargar estudiantes por CSV, armar equipos mixtos, crear actividad con peso y muro, calificar con rúbrica, **editar el plan de colaboración**, **descargar plan e informe en Word y notas en CSV**, emitir insignia (solo si la nota llega al mínimo) |
| Cualquiera | Botón *Equivalencias Moodle*: muestra en cada pantalla qué módulo de Moodle la implementa |

**Estructura del código** (secciones numeradas en el archivo):
1. `T`: todos los textos ES/EN. Agregar un idioma es copiar un bloque.
2. `seed()`: datos de ejemplo con la misma forma que `db/schema.sql`.
3. Estado y persistencia (`localStorage`, solo en ese navegador).
4. Utilidades: fechas en doble zona horaria, franja común de reunión, progreso.
5. **Acciones:** cada función lleva como comentario el endpoint REST equivalente (`POST /api/v1/activities/:id/submissions`, etc.). Para conectar un backend real se reemplaza el cuerpo de cada función por un `fetch`, y nada más cambia.
6. Vistas: funciones que devuelven HTML a partir del estado.
7. Render y eventos: un único *listener* por tipo de evento (`data-act`, `data-form`, `data-change`).

**Límites conocidos del prototipo:** no hay autenticación real, los datos no se comparten entre navegadores, y la fecha de las actividades creadas desde la plantilla se distribuye automáticamente entre inicio y fin. Son límites aceptados: el prototipo valida flujos y lenguaje visual, no es el producto.

---

### C.1 Ajustes tras revisar la documentación del programa (plan, reporte y evidencias)

Se revisaron el plan de colaboración, el modelo de reporte y el documento de evidencias del programa Global Shared Learning. Lo que ya hacían con Word, Padlet y Slack pasa ahora a la plataforma:

| Hallazgo en los documentos | Cambio en el prototipo y el modelo de datos |
|---|---|
| Cuatro actividades con peso: rompehielo 20 %, colaborativa 30 % + 30 %, reflexión 20 % | `activity.weight`; nota total ponderada (`student_grade`) y aviso si los pesos no suman 100 % |
| Aprueban y reciben insignia quienes llegan al 70 % | `project.pass_pct`; la insignia solo se puede emitir si la nota alcanza el mínimo |
| Videos de 1 a 3 minutos publicados en Padlet, una columna por equipo | Pestaña **Muro**: tarjetas por equipo, "me gusta", comentarios; el video se enlaza (YouTube, OneDrive, Teams) y no se aloja |
| "Comenta al menos a otros dos compañeros" | `activity.min_comments`; la actividad no cuenta como completa hasta cumplirlo |
| Plan de colaboración en Word (cursos, calendarios, objetivos, ODS, estrategia, cronograma, herramientas) | Pestaña **Plan**: formulario que genera el documento y lo descarga en Word; el cronograma sale de las actividades |
| Semestres que no coinciden y una ventana común de colaboración | `project.starts_on/ends_on` = ventana; calendario y horario de clase por universidad dentro de `project.plan` |
| Reporte con secciones y límite de palabras (3 páginas, 500 palabras por discusión) | `activity.template` y `submission.sections`; contador de palabras en vivo y bloqueo al exceder |
| Documento de evidencias con resumen, participantes y capturas | Pestaña **Informe** (docente): resumen automático, participantes con nota, actividades con promedio, enlaces a los videos; descarga en Word y notas en CSV |
| Ambas universidades hispanohablantes (Quito y Chihuahua) | Los datos de ejemplo pasan a español y a una hora de diferencia; el soporte ES/EN se mantiene para futuros socios |

**Pendiente de confirmar con el ingeniero:** quién emite la insignia (EPN o el programa), quién califica cada actividad (cada docente a los suyos o entre ambos), si los videos pueden alojarse en la plataforma y qué consentimiento de imagen existe.

**No subir al repositorio** los documentos originales del programa: incluyen datos de contacto y claves de acceso de los tableros.

---

## D. Plan de integración futura con Moodle y otros LMS

### D.1 Por fases

| Fase | Duración orientativa | Qué se hace | Código propio |
|---|---|---|---|
| **0. Prototipo** | 2–3 semanas | Validar este prototipo con 2 docentes y 4–6 estudiantes de cada lado; ajustar en Figma | No |
| **1. Piloto Moodle-first** | 1 semestre | Categoría Aula COIL, plantilla `.mbz`, tema EPN, matrícula del socio por CSV (cuentas invitadas) | No |
| **2. LTI 1.3 con el socio** | 2–4 semanas de configuración | Moodle EPN: *Administración › Plugins › Matriculaciones › Publicar como herramienta LTI*. El socio registra la herramienta en su LMS (registro dinámico). Se activan NRPS (lista) y AGS (notas) | No |
| **3. Automatización** | según necesidad | Scripts con Web Services de Moodle para crear cursos COIL desde una plantilla, cargar grupos y exportar reportes | Mínimo (scripts) |
| **4. Experiencia COIL a medida** | solo si el piloto lo justifica | Un bloque o formato de curso Moodle (PHP) con fechas dobles y franja de reunión; o la Ruta 2 como herramienta LTI | Sí, acotado |

### D.2 Secuencia LTI 1.3 (la universidad socia entra a Moodle EPN)

Diagrama editable: *"COIL MVP - Ingreso de la universidad socia por LTI 1.3"* en el tablero FigJam.

1. El estudiante socio abre el enlace "Aula COIL" dentro del curso de su LMS.
2. Inicio de sesión OIDC de terceros → el LMS socio envía un `id_token` JWT firmado (usuario, rol, contexto).
3. Moodle valida la firma con el JWKS del socio, crea o vincula la cuenta, matricula y asigna el grupo.
4. **NRPS** sincroniza la lista de participantes; **AGS** devuelve las notas publicadas al calificador del socio.

Resultado: cada universidad conserva su LMS y sus notas oficiales. No hay contraseñas nuevas ni exportaciones manuales.

### D.3 Contratos de API y puntos de extensión desacoplados

La regla: **el núcleo COIL nunca habla directamente con un LMS concreto**; lo hace a través de un **puerto** con adaptadores intercambiables.

```
Puerto "LmsAdapter"
  syncRoster(projectId)        → Moodle WS core_enrol_get_enrolled_users | LTI NRPS | CSV/OneRoster
  pushGrade(evaluation)        → Moodle WS core_grades_update_grades     | LTI AGS
  createCourse(template)       → Moodle WS core_course_create_courses + restauración de plantilla
  linkExternal(entity, ref)    → guarda el id externo en external_ref (jsonb)
```

**API REST de la Ruta 2** (`/api/v1`, JSON, versionada; cada acción del prototipo ya lleva su endpoint):

| Método y ruta | Acción del prototipo | Equivalente en Moodle (Ruta 1) |
|---|---|---|
| `POST /projects` | `createProject` | `core_course_create_courses` + restaurar plantilla |
| `POST /projects/:id/members:import` | `importStudents` | `enrol_manual_enrol_users` / Subir usuarios |
| `POST /projects/:id/teams:auto` · `PATCH /projects/:id/members/:personId` | `autoTeams` · `moveMember` | `core_group_create_groups` · `core_group_add_group_members` |
| `POST /projects/:id/activities` | `createActivity` | Crear Tarea desde la plantilla |
| `POST /activities/:id/submissions` | `submit` | `mod_assign_save_submission` + `mod_assign_submit_for_grading` |
| `POST /submissions/:id/evaluations` | `grade` | `mod_assign_save_grade` (con datos de rúbrica) |
| `POST /projects/:id/reflections` | `reflect` | Entrega de texto en línea |
| `POST /projects/:id/posts` | `post` | `mod_forum_add_discussion` / `mod_forum_add_discussion_post` |
| `POST /projects/:id/badges` | `badge` | Insignia automática por finalización de curso |
| `GET /projects/:id/progress` | vista *Progreso* | `core_completion_get_activities_completion_status` |

**Eventos (outbox `domain_event` en la Ruta 2; Events API en Moodle):**
`submission.created`, `evaluation.published`, `badge.issued`, `member.joined`. Un único *worker* los lee y los envía a webhooks (correo, Teams, analítica). Agregar una integración nueva consiste en suscribirse a un evento; el núcleo no cambia.

**Estándares de interoperabilidad:** LTI 1.3 + Advantage (NRPS, AGS, Deep Linking), Open Badges 2.0 (Moodle) con evolución a 3.0, CSV compatible con OneRoster para matrículas e iCal para calendarios.

---

## E. Checklist de validación técnica y funcional para el lanzamiento del piloto

### E.1 Técnica
- [ ] Versión de Moodle EPN con soporte LTI 1.3 Advantage como herramienta (Moodle 4.x).
- [ ] Categoría "Aula COIL" creada con permisos de *gestor de categoría* para la coordinación COIL.
- [ ] Plantilla `.mbz` restaurada sin errores en un curso de prueba.
- [ ] Herramienta LTI publicada, registrada por el socio, y lanzamiento probado con un docente y un estudiante del socio.
- [ ] NRPS: la lista del socio se sincroniza y los grupos se asignan correctamente.
- [ ] AGS: una nota publicada en Moodle EPN aparece en el LMS socio.
- [ ] Zonas horarias: perfiles de usuarios socios con su zona (p. ej. `Europe/Amsterdam`); una fecha de prueba se ve bien en ambos lados.
- [ ] Paquetes de idioma ES y EN instalados; filtro multilenguaje activo.
- [ ] Correo saliente (SMTP) y cron funcionando: llegan los recordatorios de entrega.
- [ ] Copias de seguridad del curso programadas.
- [ ] Prueba con 2 navegadores y 1 móvil por lado; tiempo de carga del aula menor a 3 s.

### E.2 Funcional (recorrido completo por rol)
- [ ] Docente EPN crea un curso COIL desde la plantilla en menos de 15 minutos.
- [ ] Carga de estudiantes por CSV con asignación a grupos mixtos (ningún equipo de una sola institución).
- [ ] Estudiante socio entra sin crear contraseña nueva y ve la interfaz en inglés.
- [ ] Foro en grupos separados: cada equipo ve solo su canal y el general.
- [ ] Entrega en grupo: un integrante entrega y el resto ve la misma entrega.
- [ ] Reflexión por fase enviada y visible solo para quien corresponde.
- [ ] Rúbrica compartida aplicada; la retroalimentación llega al estudiante.
- [ ] Finalización de curso calculada; la insignia se emite automáticamente.
- [ ] Sesión sincrónica: el enlace de Zoom/Teams funciona para ambos lados.

### E.3 Pedagógica y multicultural
- [ ] Acuerdo firmado entre docentes: objetivos comunes, rúbrica, calendario y peso de la nota en cada asignatura.
- [ ] Consignas clave en ambos idiomas.
- [ ] Actividad de la fase 1 (rompehielos) planificada antes de cualquier entrega calificada.
- [ ] Al menos una sesión sincrónica dentro de la franja común de los equipos.
- [ ] Guía de 1 página para estudiantes: cómo entrar, normas de comunicación, a quién escribir.

### E.4 Datos personales, accesibilidad y soporte
- [ ] Base legal y aviso de privacidad conforme a la **LOPDP de Ecuador**; si la socia está en la UE, acuerdo de tratamiento de datos compatible con el **RGPD**.
- [ ] Solo se comparten con el socio los datos mínimos (nombre, correo institucional, notas del curso COIL).
- [ ] Contraste y navegación por teclado verificados en las pantallas principales (WCAG 2.1 AA).
- [ ] Canal de soporte definido (mesa de ayuda EPN + contacto técnico del socio) y tiempo de respuesta acordado.

### E.5 Métricas del piloto (para decidir si se pasa a la fase 4 de D.1)
- [ ] ≥ 80 % de estudiantes de cada institución completa la fase 1.
- [ ] ≥ 70 % de los equipos entrega el producto final.
- [ ] Satisfacción docente ≥ 4/5 y tiempo de preparación ≤ 2 h por curso.
- [ ] Cero incidentes de acceso sin resolver por más de 48 h.
- [ ] Lista de mejoras priorizada: solo se programa lo que Moodle core no cubrió durante el piloto.
