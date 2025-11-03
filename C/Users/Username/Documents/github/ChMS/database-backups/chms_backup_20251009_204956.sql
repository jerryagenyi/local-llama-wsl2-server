--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: badge_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.badge_types (
    id bigint NOT NULL,
    organization_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    color character varying(7) DEFAULT '#007bff'::character varying NOT NULL,
    icon character varying(50) DEFAULT 'badge'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.badge_types OWNER TO postgres;

--
-- Name: badge_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.badge_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.badge_types_id_seq OWNER TO postgres;

--
-- Name: badge_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.badge_types_id_seq OWNED BY public.badge_types.id;


--
-- Name: cache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache OWNER TO postgres;

--
-- Name: cache_locks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache_locks OWNER TO postgres;

--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.failed_jobs OWNER TO postgres;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO postgres;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: families; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.families (
    id bigint NOT NULL,
    organization_id bigint NOT NULL,
    family_name character varying(255) NOT NULL,
    description text,
    address character varying(255),
    city character varying(255),
    state character varying(255),
    postal_code character varying(255),
    country character varying(255),
    home_phone character varying(255),
    email character varying(255),
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.families OWNER TO postgres;

--
-- Name: families_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.families_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.families_id_seq OWNER TO postgres;

--
-- Name: families_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.families_id_seq OWNED BY public.families.id;


--
-- Name: job_batches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE public.job_batches OWNER TO postgres;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE public.jobs OWNER TO postgres;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO postgres;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: member_attribute_values; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member_attribute_values (
    id bigint NOT NULL,
    member_id bigint NOT NULL,
    attribute_id bigint NOT NULL,
    value text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.member_attribute_values OWNER TO postgres;

--
-- Name: member_attribute_values_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.member_attribute_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.member_attribute_values_id_seq OWNER TO postgres;

--
-- Name: member_attribute_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.member_attribute_values_id_seq OWNED BY public.member_attribute_values.id;


--
-- Name: member_attributes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member_attributes (
    id bigint NOT NULL,
    organization_id bigint NOT NULL,
    key character varying(100) NOT NULL,
    name character varying(255) NOT NULL,
    field_type character varying(255) NOT NULL,
    category character varying(100) DEFAULT 'Personal'::character varying NOT NULL,
    field_options json,
    is_required boolean DEFAULT false NOT NULL,
    display_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    CONSTRAINT member_attributes_field_type_check CHECK (((field_type)::text = ANY ((ARRAY['text'::character varying, 'textarea'::character varying, 'number'::character varying, 'date'::character varying, 'boolean'::character varying, 'select'::character varying, 'email'::character varying, 'phone'::character varying])::text[])))
);


ALTER TABLE public.member_attributes OWNER TO postgres;

--
-- Name: member_attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.member_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.member_attributes_id_seq OWNER TO postgres;

--
-- Name: member_attributes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.member_attributes_id_seq OWNED BY public.member_attributes.id;


--
-- Name: member_badges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member_badges (
    id bigint NOT NULL,
    member_id bigint NOT NULL,
    badge_type_id bigint NOT NULL,
    assigned_by bigint,
    assigned_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp(0) without time zone,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.member_badges OWNER TO postgres;

--
-- Name: member_badges_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.member_badges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.member_badges_id_seq OWNER TO postgres;

--
-- Name: member_badges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.member_badges_id_seq OWNED BY public.member_badges.id;


--
-- Name: member_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member_notes (
    id bigint NOT NULL,
    member_id bigint NOT NULL,
    author_id bigint NOT NULL,
    title character varying(255),
    content text NOT NULL,
    note_type character varying(255) DEFAULT 'Personal Note'::character varying NOT NULL,
    privacy_level character varying(255) DEFAULT 'public'::character varying NOT NULL,
    is_alert boolean DEFAULT false NOT NULL,
    is_pinned boolean DEFAULT false NOT NULL,
    alert_expires_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    CONSTRAINT member_notes_privacy_level_check CHECK (((privacy_level)::text = ANY ((ARRAY['public'::character varying, 'private'::character varying, 'extreme'::character varying])::text[])))
);


ALTER TABLE public.member_notes OWNER TO postgres;

--
-- Name: member_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.member_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.member_notes_id_seq OWNER TO postgres;

--
-- Name: member_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.member_notes_id_seq OWNED BY public.member_notes.id;


--
-- Name: members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.members (
    id bigint NOT NULL,
    organization_id bigint NOT NULL,
    family_id bigint,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    middle_name character varying(255),
    email character varying(255),
    phone character varying(255),
    date_of_birth date,
    gender character varying(255),
    marital_status character varying(255),
    member_type character varying(255) DEFAULT 'visitor'::character varying NOT NULL,
    joined_date date,
    baptism_date date,
    membership_date date,
    address character varying(255),
    city character varying(255),
    state character varying(255),
    postal_code character varying(255),
    country character varying(255),
    emergency_contact_name character varying(255),
    emergency_contact_phone character varying(255),
    emergency_contact_relationship character varying(255),
    notes text,
    photo_url character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    CONSTRAINT members_gender_check CHECK (((gender)::text = ANY ((ARRAY['male'::character varying, 'female'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT members_marital_status_check CHECK (((marital_status)::text = ANY ((ARRAY['single'::character varying, 'married'::character varying, 'divorced'::character varying, 'widowed'::character varying])::text[]))),
    CONSTRAINT members_member_type_check CHECK (((member_type)::text = ANY ((ARRAY['member'::character varying, 'visitor'::character varying, 'regular_attendee'::character varying])::text[])))
);


ALTER TABLE public.members OWNER TO postgres;

--
-- Name: members_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.members_id_seq OWNER TO postgres;

--
-- Name: members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.members_id_seq OWNED BY public.members.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: organization_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.organization_settings (
    id bigint NOT NULL,
    organization_id bigint NOT NULL,
    setting_key character varying(100) NOT NULL,
    setting_value text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.organization_settings OWNER TO postgres;

--
-- Name: organization_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.organization_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.organization_settings_id_seq OWNER TO postgres;

--
-- Name: organization_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.organization_settings_id_seq OWNED BY public.organization_settings.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.organizations (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    address text,
    phone character varying(50),
    email character varying(255),
    website character varying(255),
    description text,
    timezone character varying(50) DEFAULT 'Africa/Lagos'::character varying NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.organizations OWNER TO postgres;

--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.organizations_id_seq OWNER TO postgres;

--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.organizations_id_seq OWNED BY public.organizations.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.password_reset_tokens OWNER TO postgres;

--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id bigint NOT NULL,
    name text NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp(0) without time zone,
    expires_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.personal_access_tokens OWNER TO postgres;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personal_access_tokens_id_seq OWNER TO postgres;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- Name: service_schedules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_schedules (
    id bigint NOT NULL,
    organization_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    day_of_week smallint NOT NULL,
    start_time time(0) without time zone NOT NULL,
    end_time time(0) without time zone,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.service_schedules OWNER TO postgres;

--
-- Name: COLUMN service_schedules.day_of_week; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.service_schedules.day_of_week IS '0=Sunday, 1=Monday, etc.';


--
-- Name: service_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_schedules_id_seq OWNER TO postgres;

--
-- Name: service_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_schedules_id_seq OWNED BY public.service_schedules.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    user_id bigint,
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    email_verified_at timestamp(0) without time zone,
    password character varying(255) NOT NULL,
    remember_token character varying(100),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    first_name character varying(255),
    last_name character varying(255),
    phone character varying(255),
    role character varying(255) DEFAULT 'member'::character varying NOT NULL,
    organization_id bigint,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'staff'::character varying, 'member'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: badge_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.badge_types ALTER COLUMN id SET DEFAULT nextval('public.badge_types_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: families id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.families ALTER COLUMN id SET DEFAULT nextval('public.families_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: member_attribute_values id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_attribute_values ALTER COLUMN id SET DEFAULT nextval('public.member_attribute_values_id_seq'::regclass);


--
-- Name: member_attributes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_attributes ALTER COLUMN id SET DEFAULT nextval('public.member_attributes_id_seq'::regclass);


--
-- Name: member_badges id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_badges ALTER COLUMN id SET DEFAULT nextval('public.member_badges_id_seq'::regclass);


--
-- Name: member_notes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_notes ALTER COLUMN id SET DEFAULT nextval('public.member_notes_id_seq'::regclass);


--
-- Name: members id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.members ALTER COLUMN id SET DEFAULT nextval('public.members_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: organization_settings id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organization_settings ALTER COLUMN id SET DEFAULT nextval('public.organization_settings_id_seq'::regclass);


--
-- Name: organizations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations ALTER COLUMN id SET DEFAULT nextval('public.organizations_id_seq'::regclass);


--
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- Name: service_schedules id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_schedules ALTER COLUMN id SET DEFAULT nextval('public.service_schedules_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: badge_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.badge_types (id, organization_id, name, description, color, icon, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cache (key, value, expiration) FROM stdin;
\.


--
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cache_locks (key, owner, expiration) FROM stdin;
\.


--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- Data for Name: families; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.families (id, organization_id, family_name, description, address, city, state, postal_code, country, home_phone, email, notes, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- Data for Name: member_attribute_values; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.member_attribute_values (id, member_id, attribute_id, value, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: member_attributes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.member_attributes (id, organization_id, key, name, field_type, category, field_options, is_required, display_order, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: member_badges; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.member_badges (id, member_id, badge_type_id, assigned_by, assigned_at, expires_at, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: member_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.member_notes (id, member_id, author_id, title, content, note_type, privacy_level, is_alert, is_pinned, alert_expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.members (id, organization_id, family_id, first_name, last_name, middle_name, email, phone, date_of_birth, gender, marital_status, member_type, joined_date, baptism_date, membership_date, address, city, state, postal_code, country, emergency_contact_name, emergency_contact_phone, emergency_contact_relationship, notes, photo_url, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.migrations (id, migration, batch) FROM stdin;
38	0001_01_01_000000_create_users_table	1
39	0001_01_01_000001_create_cache_table	1
40	0001_01_01_000002_create_jobs_table	1
41	2025_10_05_072331_create_personal_access_tokens_table	1
42	2025_10_05_084311_add_additional_fields_to_users_table	1
43	2025_10_05_235959_create_families_table	1
44	2025_10_06_000000_create_members_table	1
45	2025_10_06_000001_create_member_attributes_table	1
46	2025_10_06_000002_create_member_attribute_values_table	1
47	2025_10_06_000003_create_badge_types_table	1
48	2025_10_06_000004_create_member_badges_table	1
49	2025_10_06_000005_create_member_notes_table	1
50	2025_10_06_135521_create_organizations_table	1
51	2025_10_06_135527_create_organization_settings_table	1
52	2025_10_06_135534_create_service_schedules_table	1
53	2025_10_06_135831_modify_organization_id_in_users_table	1
54	2025_10_09_144944_add_foreign_keys_after_all_tables	1
\.


--
-- Data for Name: organization_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.organization_settings (id, organization_id, setting_key, setting_value, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: organizations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.organizations (id, name, address, phone, email, website, description, timezone, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.password_reset_tokens (email, token, created_at) FROM stdin;
\.


--
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: service_schedules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_schedules (id, organization_id, name, day_of_week, start_time, end_time, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, email_verified_at, password, remember_token, created_at, updated_at, first_name, last_name, phone, role, organization_id) FROM stdin;
\.


--
-- Name: badge_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.badge_types_id_seq', 1, false);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- Name: families_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.families_id_seq', 1, false);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- Name: member_attribute_values_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.member_attribute_values_id_seq', 1, false);


--
-- Name: member_attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.member_attributes_id_seq', 1, false);


--
-- Name: member_badges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.member_badges_id_seq', 1, false);


--
-- Name: member_notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.member_notes_id_seq', 1, false);


--
-- Name: members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.members_id_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.migrations_id_seq', 54, true);


--
-- Name: organization_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.organization_settings_id_seq', 1, false);


--
-- Name: organizations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.organizations_id_seq', 1, false);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personal_access_tokens_id_seq', 1, false);


--
-- Name: service_schedules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_schedules_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- Name: badge_types badge_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.badge_types
    ADD CONSTRAINT badge_types_pkey PRIMARY KEY (id);


--
-- Name: cache_locks cache_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: families families_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.families
    ADD CONSTRAINT families_pkey PRIMARY KEY (id);


--
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: member_attribute_values member_attribute_values_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_attribute_values
    ADD CONSTRAINT member_attribute_values_pkey PRIMARY KEY (id);


--
-- Name: member_attributes member_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_attributes
    ADD CONSTRAINT member_attributes_pkey PRIMARY KEY (id);


--
-- Name: member_badges member_badges_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_badges
    ADD CONSTRAINT member_badges_pkey PRIMARY KEY (id);


--
-- Name: member_notes member_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_notes
    ADD CONSTRAINT member_notes_pkey PRIMARY KEY (id);


--
-- Name: members members_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_email_unique UNIQUE (email);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: organization_settings organization_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organization_settings
    ADD CONSTRAINT organization_settings_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- Name: service_schedules service_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_schedules
    ADD CONSTRAINT service_schedules_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: member_attribute_values unique_member_attribute; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_attribute_values
    ADD CONSTRAINT unique_member_attribute UNIQUE (member_id, attribute_id);


--
-- Name: member_badges unique_member_badge; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_badges
    ADD CONSTRAINT unique_member_badge UNIQUE (member_id, badge_type_id);


--
-- Name: badge_types unique_org_badge_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.badge_types
    ADD CONSTRAINT unique_org_badge_name UNIQUE (organization_id, name);


--
-- Name: member_attributes unique_org_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_attributes
    ADD CONSTRAINT unique_org_key UNIQUE (organization_id, key);


--
-- Name: organization_settings unique_org_setting; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organization_settings
    ADD CONSTRAINT unique_org_setting UNIQUE (organization_id, setting_key);


--
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: families_organization_id_family_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX families_organization_id_family_name_index ON public.families USING btree (organization_id, family_name);


--
-- Name: families_organization_id_is_active_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX families_organization_id_is_active_index ON public.families USING btree (organization_id, is_active);


--
-- Name: idx_attribute_values_attribute; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attribute_values_attribute ON public.member_attribute_values USING btree (attribute_id);


--
-- Name: idx_attribute_values_member; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attribute_values_member ON public.member_attribute_values USING btree (member_id);


--
-- Name: idx_attributes_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attributes_category ON public.member_attributes USING btree (category);


--
-- Name: idx_attributes_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attributes_order ON public.member_attributes USING btree (display_order);


--
-- Name: idx_badges_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_badges_active ON public.badge_types USING btree (is_active);


--
-- Name: idx_member_badges_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_member_badges_expires ON public.member_badges USING btree (expires_at);


--
-- Name: idx_member_badges_member; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_member_badges_member ON public.member_badges USING btree (member_id);


--
-- Name: idx_member_badges_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_member_badges_type ON public.member_badges USING btree (badge_type_id);


--
-- Name: jobs_queue_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX jobs_queue_index ON public.jobs USING btree (queue);


--
-- Name: member_notes_author_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX member_notes_author_id_index ON public.member_notes USING btree (author_id);


--
-- Name: member_notes_created_at_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX member_notes_created_at_index ON public.member_notes USING btree (created_at);


--
-- Name: member_notes_is_alert_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX member_notes_is_alert_index ON public.member_notes USING btree (is_alert);


--
-- Name: member_notes_is_pinned_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX member_notes_is_pinned_index ON public.member_notes USING btree (is_pinned);


--
-- Name: member_notes_member_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX member_notes_member_id_index ON public.member_notes USING btree (member_id);


--
-- Name: member_notes_note_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX member_notes_note_type_index ON public.member_notes USING btree (note_type);


--
-- Name: member_notes_privacy_level_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX member_notes_privacy_level_index ON public.member_notes USING btree (privacy_level);


--
-- Name: members_email_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX members_email_index ON public.members USING btree (email);


--
-- Name: members_organization_id_is_active_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX members_organization_id_is_active_index ON public.members USING btree (organization_id, is_active);


--
-- Name: members_organization_id_last_name_first_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX members_organization_id_last_name_first_name_index ON public.members USING btree (organization_id, last_name, first_name);


--
-- Name: members_organization_id_member_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX members_organization_id_member_type_index ON public.members USING btree (organization_id, member_type);


--
-- Name: members_phone_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX members_phone_index ON public.members USING btree (phone);


--
-- Name: organization_settings_setting_key_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX organization_settings_setting_key_index ON public.organization_settings USING btree (setting_key);


--
-- Name: organizations_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX organizations_name_index ON public.organizations USING btree (name);


--
-- Name: personal_access_tokens_expires_at_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX personal_access_tokens_expires_at_index ON public.personal_access_tokens USING btree (expires_at);


--
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- Name: service_schedules_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX service_schedules_name_index ON public.service_schedules USING btree (name);


--
-- Name: service_schedules_organization_id_day_of_week_is_active_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX service_schedules_organization_id_day_of_week_is_active_index ON public.service_schedules USING btree (organization_id, day_of_week, is_active);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- Name: users_organization_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX users_organization_id_index ON public.users USING btree (organization_id);


--
-- Name: badge_types badge_types_organization_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.badge_types
    ADD CONSTRAINT badge_types_organization_id_foreign FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: families families_organization_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.families
    ADD CONSTRAINT families_organization_id_foreign FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: member_attribute_values member_attribute_values_attribute_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_attribute_values
    ADD CONSTRAINT member_attribute_values_attribute_id_foreign FOREIGN KEY (attribute_id) REFERENCES public.member_attributes(id) ON DELETE CASCADE;


--
-- Name: member_attribute_values member_attribute_values_member_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_attribute_values
    ADD CONSTRAINT member_attribute_values_member_id_foreign FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: member_attributes member_attributes_organization_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_attributes
    ADD CONSTRAINT member_attributes_organization_id_foreign FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: member_badges member_badges_assigned_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_badges
    ADD CONSTRAINT member_badges_assigned_by_foreign FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: member_badges member_badges_badge_type_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_badges
    ADD CONSTRAINT member_badges_badge_type_id_foreign FOREIGN KEY (badge_type_id) REFERENCES public.badge_types(id) ON DELETE CASCADE;


--
-- Name: member_badges member_badges_member_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_badges
    ADD CONSTRAINT member_badges_member_id_foreign FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: member_notes member_notes_author_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_notes
    ADD CONSTRAINT member_notes_author_id_foreign FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: member_notes member_notes_member_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member_notes
    ADD CONSTRAINT member_notes_member_id_foreign FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: members members_family_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_family_id_foreign FOREIGN KEY (family_id) REFERENCES public.families(id) ON DELETE SET NULL;


--
-- Name: members members_organization_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_organization_id_foreign FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: organization_settings organization_settings_organization_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.organization_settings
    ADD CONSTRAINT organization_settings_organization_id_foreign FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: service_schedules service_schedules_organization_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_schedules
    ADD CONSTRAINT service_schedules_organization_id_foreign FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: users users_organization_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_organization_id_foreign FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

