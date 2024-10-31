SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: diagram; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.diagram AS ENUM (
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


--
-- Name: location; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.location AS ENUM (
    'SYSTEM',
    'GIST'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id bigint NOT NULL,
    uid character varying NOT NULL,
    diagram_id uuid,
    location public.location NOT NULL,
    diagram public.diagram NOT NULL,
    is_bookmark boolean,
    is_public boolean,
    title character varying,
    text text NOT NULL,
    thumbnail text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);

ALTER TABLE ONLY public.items FORCE ROW LEVEL SECURITY;


--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(128) NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id bigint NOT NULL,
    uid character varying NOT NULL,
    activity_color character varying NOT NULL,
    activity_background_color character varying NOT NULL,
    background_color character varying NOT NULL,
    diagram public.diagram NOT NULL,
    height integer NOT NULL,
    font character varying NOT NULL,
    line_color character varying NOT NULL,
    label_color character varying NOT NULL,
    lock_editing boolean,
    text_color character varying,
    toolbar boolean,
    scale real,
    show_grid boolean,
    story_color character varying NOT NULL,
    story_background_color character varying NOT NULL,
    task_color character varying NOT NULL,
    task_background_color character varying NOT NULL,
    width integer NOT NULL,
    zoom_control boolean,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.settings FORCE ROW LEVEL SECURITY;


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: share_conditions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.share_conditions (
    id bigint NOT NULL,
    hashkey character varying NOT NULL,
    uid character varying NOT NULL,
    diagram_id uuid,
    location public.location NOT NULL,
    allow_ip_list character varying[],
    allow_email_list character varying[],
    expire_time bigint,
    password character varying,
    token character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);

ALTER TABLE ONLY public.share_conditions FORCE ROW LEVEL SECURITY;


--
-- Name: share_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.share_conditions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: share_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.share_conditions_id_seq OWNED BY public.share_conditions.id;


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: share_conditions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_conditions ALTER COLUMN id SET DEFAULT nextval('public.share_conditions_id_seq'::regclass);


--
-- Name: items items_diagram_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_diagram_id_key UNIQUE (diagram_id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: share_conditions share_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.share_conditions
    ADD CONSTRAINT share_conditions_pkey PRIMARY KEY (id);


--
-- Name: items_uid_location_diagram_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX items_uid_location_diagram_id_idx ON public.items USING btree (uid, location, diagram_id);


--
-- Name: settings_uid_diagram_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX settings_uid_diagram_idx ON public.settings USING btree (uid, diagram);


--
-- Name: share_hashkey_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX share_hashkey_idx ON public.share_conditions USING btree (hashkey);


--
-- Name: share_uid_location_diagram_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX share_uid_location_diagram_id_idx ON public.share_conditions USING btree (uid, location, diagram_id);


--
-- Name: items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

--
-- Name: items items_uid_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY items_uid_policy ON public.items USING (((uid)::text = current_setting(('app.uid'::character varying)::text)));


--
-- Name: settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

--
-- Name: settings settings_uid_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY settings_uid_policy ON public.settings USING (((uid)::text = current_setting(('app.uid'::character varying)::text)));


--
-- Name: share_conditions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.share_conditions ENABLE ROW LEVEL SECURITY;

--
-- Name: share_conditions share_conditions_uid_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY share_conditions_uid_policy ON public.share_conditions USING (((uid)::text = current_setting(('app.uid'::character varying)::text)));


--
-- PostgreSQL database dump complete
--


--
-- Dbmate schema migrations
--

INSERT INTO public.schema_migrations (version) VALUES
    ('20241012091142');
