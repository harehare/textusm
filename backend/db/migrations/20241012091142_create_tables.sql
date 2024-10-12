-- migrate:up
CREATE TYPE diagram AS ENUM(
  'USER_STORY_MAP',
  'OPPORTUNITY_CANVAS',
  'BUSINESS_MODEL_CANVAS',
  'FOURLS',
  'START_STOP_CONTINUE',
  'KPT',
  'USER_PERSONA',
  'MIND_MAP',
  'EMPATHY_MAP',
  'SITE_MAP',
  'GANTT_CHART',
  'IMPACT_MAP',
  'ER_DIAGRAM',
  'KANBAN',
  'TABLE',
  'SEQUENCE_DIAGRAM',
  'FREEFORM',
  'USE_CASE_DIAGRAM',
  'KEYBOARD_LAYOUT'
);

CREATE TYPE location AS ENUM('SYSTEM', 'GIST');

CREATE TABLE
  items (
    id bigserial PRIMARY KEY,
    uid varchar NOT NULL,
    diagram_id UUID UNIQUE,
    location location NOT NULL,
    diagram diagram NOT NULL,
    is_bookmark boolean,
    is_public boolean,
    title varchar,
    text text NOT NULL,
    thumbnail text,
    created_at timestamp DEFAULT NOW(),
    updated_at timestamp DEFAULT NOW()
  );

CREATE TABLE
  share_conditions (
    id bigserial PRIMARY KEY,
    uid varchar NOT NULL,
    diagram_id UUID,
    allow_ip_list varchar[],
    allow_email_list varchar[],
    expire_time int,
    password varchar,
    token varchar NOT NULL,
    created_at timestamp DEFAULT NOW(),
    updated_at timestamp DEFAULT NOW()
  );

CREATE TABLE
  settings (
    id bigserial PRIMARY KEY,
    uid varchar NOT NULL,
    activity_color varchar,
    activity_background_color varchar,
    background_color varchar,
    diagram diagram NOT NULL,
    height int,
    line_color varchar,
    label_color varchar,
    lock_editing boolean,
    text_color varchar,
    toolbar boolean,
    scale real,
    show_grid boolean,
    story_color varchar,
    story_background_color varchar,
    task_color varchar,
    task_background_color varchar,
    width int,
    zoom_control boolean,
    created_at timestamp DEFAULT NOW(),
    updated_at timestamp DEFAULT NOW()
  );

CREATE INDEX items_idx ON items (diagram_id);

-- migrate:down
DROP TABLE items;

DROP TABLE share_conditions;

DROP TABLE settings;

DROP TYPE diagram;

DROP TYPE location;

DROP INDEX items_idx;
