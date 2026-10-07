-- =====================================================================
-- Aula COIL · modelo de datos mínimo (PostgreSQL 14+)
--
-- Uso:
--   * Ruta 1 (recomendada, Moodle-first): NO se crea esta base. Es el
--     modelo de dominio y cada tabla se corresponde con tablas de Moodle
--     (ver comentarios "Moodle:"). Sirve para reportes y para conversar
--     con la universidad socia con un vocabulario común.
--   * Ruta 2 (app propia ligera): esquema listo para usar.
--
-- Reglas de diseño:
--   * 12 tablas, sin herencia ni tablas polimórficas.
--   * Fechas siempre en UTC (timestamptz); la zona horaria es de la persona.
--   * Textos bilingües solo donde aportan (títulos): jsonb {"es": "...", "en": "..."}.
--   * external_ref permite enlazar cualquier fila con su par en Moodle u otro LMS
--     sin cambiar el esquema.
-- =====================================================================

create table institution (            -- Moodle: campo de perfil "institution" / cohorte
  id            text primary key,     -- 'epn', 'pu'
  name          text not null,
  country       text not null,
  timezone      text not null,        -- IANA, p. ej. 'America/Guayaquil'
  default_lang  text not null default 'es'
);

create table person (                 -- Moodle: mdl_user
  id             uuid primary key default gen_random_uuid(),
  institution_id text not null references institution(id),
  email          text not null unique,
  full_name      text not null,
  lang           text not null default 'es',
  timezone       text not null,
  external_ref   jsonb not null default '{}'  -- {"moodle_epn": 1234, "lti_sub": "..."}
);

create table project (                -- Moodle: mdl_course dentro de la categoría "Aula COIL"
  id            uuid primary key default gen_random_uuid(),
  title         jsonb not null,       -- {"es": "...", "en": "..."}
  description   jsonb not null default '{}',
  institutions  text[] not null,      -- {'epn','pu'}
  courses       jsonb not null default '{}', -- {"epn": "Business Intelligence (ISWD743)", "pu": "..."}
  term          text,
  starts_on     date not null,     -- ventana de colaboración (no el semestre completo)
  ends_on       date not null,
  pass_pct      smallint not null default 70 check (pass_pct between 1 and 100), -- % mínimo para aprobar y recibir insignia
  plan          jsonb not null default '{}',  -- plan de colaboración: objectives, ods[], strategy[], tools{}, inst{<id>: {schedule, semStart, semEnd, breaks}}
  status        text not null default 'draft' check (status in ('draft','active','closed')),
  meet_url      text,                 -- integración opcional Zoom/Teams
  drive_url     text,                 -- integración opcional Drive/OneDrive
  external_ref  jsonb not null default '{}',
  check (ends_on > starts_on)
);

create table team (                   -- Moodle: mdl_groups (+ agrupamiento "Equipos COIL")
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references project(id) on delete cascade,
  name        text not null,
  unique (project_id, name)
);

create table project_member (         -- Moodle: mdl_user_enrolments + mdl_role_assignments + mdl_groups_members
  project_id      uuid not null references project(id) on delete cascade,
  person_id       uuid not null references person(id),
  role            text not null check (role in ('teacher','student')),
  team_id         uuid references team(id) on delete set null,
  badge_issued_at timestamptz,        -- Moodle: mdl_badge_issued
  primary key (project_id, person_id)
);

create table activity (               -- Moodle: mdl_assign (task, reflection) / mod_zoom o mdl_url (session)
  id            uuid primary key default gen_random_uuid(),
  project_id    uuid not null references project(id) on delete cascade,
  phase         smallint not null check (phase between 1 and 4),
  kind          text not null check (kind in ('task','reflection','session')),
  mode          text not null default 'individual' check (mode in ('individual','team')),
  title         jsonb not null,
  instructions  text not null default '',
  due_at        timestamptz not null, -- UTC
  weight        numeric(5,2) not null default 0 check (weight between 0 and 100), -- % de la nota total; 0 = sin nota
  wall          boolean not null default false,  -- se publica en el muro de videos
  min_comments  smallint not null default 0,     -- comentarios mínimos a compañeros (muro)
  template      jsonb,                -- reporte con secciones: [{"es":"Discusión","en":"Discussion","max":500}] (max = palabras)
  rubric        jsonb,                -- [{"es":"Colaboración","en":"Collaboration","max":4}, ...]
  external_ref  jsonb not null default '{}'
);
create index on activity (project_id, due_at);

create table resource (               -- Moodle: mdl_url / mdl_resource / mdl_book
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references project(id) on delete cascade,
  title       text not null,
  url         text not null,
  lang        text not null default 'es'
);

create table submission (             -- Moodle: mdl_assign_submission (+ onlinetext / files)
  id            uuid primary key default gen_random_uuid(),
  activity_id   uuid not null references activity(id) on delete cascade,
  team_id       uuid references team(id),          -- null si es individual
  author_id     uuid not null references person(id),
  body          text not null,
  sections      jsonb,                -- respuestas por sección cuando la actividad tiene template
  link_url      text,                 -- video (YouTube, OneDrive, Teams) o documento
  submitted_at  timestamptz not null default now()
);
-- una entrega por equipo o por persona; las actualizaciones reemplazan la fila
create unique index submission_team_uq on submission (activity_id, team_id) where team_id is not null;
create unique index submission_ind_uq  on submission (activity_id, author_id) where team_id is null;

create table submission_like (        -- reacciones "me gusta" del muro
  submission_id  uuid not null references submission(id) on delete cascade,
  person_id      uuid not null references person(id),
  primary key (submission_id, person_id)
);

create table comment (                -- comentarios del muro (Moodle: comentarios de Base de datos)
  id             uuid primary key default gen_random_uuid(),
  submission_id  uuid not null references submission(id) on delete cascade,
  author_id      uuid not null references person(id),
  body           text not null,
  created_at     timestamptz not null default now()
);

create table evaluation (             -- Moodle: mdl_assign_grades + mdl_gradingform_rubric_fillings
  id             uuid primary key default gen_random_uuid(),
  submission_id  uuid not null references submission(id) on delete cascade,
  evaluator_id   uuid not null references person(id),
  rubric_scores  jsonb not null default '[]',      -- [4, 3, 2]
  score          numeric(5,2) not null,
  feedback       text not null default '',
  created_at     timestamptz not null default now()
);

create table reflection (             -- Moodle: mdl_assign (texto en línea, sin nota)
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references project(id) on delete cascade,
  author_id   uuid not null references person(id),
  phase       smallint not null check (phase between 1 and 4),
  body        text not null,
  visibility  text not null default 'teachers' check (visibility in ('private','teachers','team')),
  created_at  timestamptz not null default now(),
  unique (project_id, author_id, phase)
);

create table post (                   -- Moodle: mdl_forum_discussions / mdl_forum_posts (modo grupos separados)
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references project(id) on delete cascade,
  team_id     uuid references team(id) on delete cascade,  -- null = canal general
  author_id   uuid not null references person(id),
  parent_id   uuid references post(id) on delete cascade,
  lang        text not null,
  body        text not null,
  created_at  timestamptz not null default now()
);

create table domain_event (           -- Moodle: Events API (observers); aquí, "outbox" para webhooks
  id             bigserial primary key,
  project_id     uuid references project(id) on delete cascade,
  type           text not null,       -- 'submission.created', 'evaluation.published', 'badge.issued'
  payload        jsonb not null,
  created_at     timestamptz not null default now(),
  dispatched_at  timestamptz          -- null = pendiente de enviar
);
create index on domain_event (dispatched_at) where dispatched_at is null;

-- Progreso: actividades requeridas (entregas y reflexiones) completadas por estudiante
create view student_progress as
select m.project_id, m.person_id,
       count(a.id) as required,
       count(a.id) filter (where
         (a.kind = 'reflection' and exists (select 1 from reflection r where r.project_id = a.project_id and r.author_id = m.person_id and r.phase = a.phase))
      or (a.kind = 'task' and a.mode = 'individual' and exists (select 1 from submission s where s.activity_id = a.id and s.author_id = m.person_id)
          and (select count(distinct c.submission_id) from comment c join submission s2 on s2.id = c.submission_id
               where s2.activity_id = a.id and s2.author_id <> m.person_id and c.author_id = m.person_id) >= a.min_comments)
      or (a.kind = 'task' and a.mode = 'team' and exists (select 1 from submission s where s.activity_id = a.id and s.team_id = m.team_id))
       ) as done
from project_member m
join activity a on a.project_id = m.project_id and a.kind <> 'session'
where m.role = 'student'
group by m.project_id, m.person_id;

-- Nota ponderada (0-100): suma de peso x (puntaje / 10) de las actividades calificadas.
-- Aprueba (y recibe insignia) quien llega a project.pass_pct.
create view student_grade as
select m.project_id, m.person_id,
       round(coalesce(sum(a.weight * e.score / 10), 0), 1) as pct,
       coalesce(sum(a.weight * e.score / 10), 0) >= p.pass_pct as passed
from project_member m
join project p on p.id = m.project_id
join activity a on a.project_id = m.project_id and a.weight > 0
left join submission s on s.activity_id = a.id
     and ((a.mode = 'team' and s.team_id = m.team_id) or (a.mode = 'individual' and s.author_id = m.person_id))
left join lateral (select score from evaluation where submission_id = s.id order by created_at desc limit 1) e on true
where m.role = 'student'
group by m.project_id, m.person_id, p.pass_pct;
