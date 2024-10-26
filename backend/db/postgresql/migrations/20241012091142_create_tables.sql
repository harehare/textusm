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
    hashkey varchar NOT NULL,
    uid varchar NOT NULL,
    diagram_id UUID,
    location location NOT NULL,
    allow_ip_list varchar[],
    allow_email_list varchar[],
    expire_time bigint,
    password varchar,
    token varchar NOT NULL,
    created_at timestamp DEFAULT NOW(),
    updated_at timestamp DEFAULT NOW()
  );

CREATE TABLE
  settings (
    id bigserial PRIMARY KEY,
    uid varchar NOT NULL,
    activity_color varchar NOT NULL,
    activity_background_color varchar NOT NULL,
    background_color varchar NOT NULL,
    diagram diagram NOT NULL,
    height int NOT NULL,
    font varchar NOT NULL,
    line_color varchar NOT NULL,
    label_color varchar NOT NULL,
    lock_editing boolean,
    text_color varchar,
    toolbar boolean,
    scale real,
    show_grid boolean,
    story_color varchar NOT NULL,
    story_background_color varchar NOT NULL,
    task_color varchar NOT NULL,
    task_background_color varchar NOT NULL,
    width int NOT NULL,
    zoom_control boolean,
    created_at timestamp DEFAULT NOW() NOT NULL,
    updated_at timestamp DEFAULT NOW() NOT NULL
  );

CREATE UNIQUE INDEX items_uid_location_diagram_id_idx ON items (uid, location, diagram_id);

CREATE UNIQUE INDEX settings_uid_diagram_idx ON settings (uid, diagram);

CREATE UNIQUE INDEX share_hashkey_idx ON share_conditions (hashkey);

CREATE UNIQUE INDEX share_uid_location_diagram_id_idx ON share_conditions (uid, location, diagram_id);

ALTER TABLE items FORCE ROW LEVEL SECURITY;

ALTER TABLE items ENABLE ROW LEVEL SECURITY;

ALTER TABLE share_conditions FORCE ROW LEVEL SECURITY;

ALTER TABLE share_conditions ENABLE ROW LEVEL SECURITY;

ALTER TABLE settings FORCE ROW LEVEL SECURITY;

ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY items_uid_policy ON items AS PERMISSIVE FOR ALL TO public USING (uid = current_setting('app.uid'::varchar));

CREATE POLICY share_conditions_uid_policy ON share_conditions AS PERMISSIVE FOR ALL TO public USING (uid = current_setting('app.uid'::varchar));

CREATE POLICY settings_uid_policy ON settings AS PERMISSIVE FOR ALL TO public USING (uid = current_setting('app.uid'::varchar));

-- migrate:down
DROP TABLE items;

DROP TABLE share_conditions;

DROP TABLE settings;

DROP TYPE diagram;

DROP TYPE location;
