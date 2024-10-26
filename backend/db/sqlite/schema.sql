CREATE TABLE IF NOT EXISTS "schema_migrations" (version varchar(128) primary key);
CREATE TABLE items (
    id integer PRIMARY KEY,
    uid text NOT NULL,
    diagram_id text NOT NULL,
    location text NOT NULL,
    diagram text NOT NULL,
    is_bookmark integer NOT NULL,
    is_public integer NOT NULL,
    title text,
    text text NOT NULL,
    thumbnail text,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  );
CREATE TABLE share_conditions (
    id integer PRIMARY KEY,
    hashkey text NOT NULL,
    uid text NOT NULL,
    diagram_id text NOT NULL,
    location text NOT NULL,
    allow_ip_list text,
    allow_email_list text,
    expire_time bigint,
    password text,
    token text NOT NULL,
    created_at integer NOT NULL,
    updated_at integer NOT NULL
  );
CREATE TABLE settings (
    id integer PRIMARY KEY,
    uid text NOT NULL,
    activity_color text NOT NULL,
    activity_background_color text NOT NULL,
    background_color text NOT NULL,
    diagram text NOT NULL,
    height integer NOT NULL,
    font text NOT NULL,
    line_color text NOT NULL,
    label_color text NOT NULL,
    lock_editing integer,
    text_color text,
    toolbar integer,
    scale real NOT NULL,
    show_grid integer,
    story_color text NOT NULL,
    story_background_color text NOT NULL,
    task_color text NOT NULL,
    task_background_color text NOT NULL,
    width integer NOT NULL,
    zoom_control integer,
    created_at integer NOT NULL,
    updated_at integer NOT NULL
  );
CREATE UNIQUE INDEX items_uid_location_diagram_id_idx ON items (uid, location, diagram_id);
CREATE UNIQUE INDEX settings_uid_diagram_idx ON settings (uid, diagram);
CREATE UNIQUE INDEX share_hashkey_idx ON share_conditions (hashkey);
CREATE UNIQUE INDEX share_uid_location_diagram_id_idx ON share_conditions (uid, location, diagram_id);
-- Dbmate schema migrations
INSERT INTO "schema_migrations" (version) VALUES
  ('20241012091142');
