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

--
-- Name: JobStatus; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."JobStatus" AS ENUM (
    'ACTIVE',
    'INACTIVE'
);


ALTER TYPE public."JobStatus" OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: LiteLLM_SpendLogs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_SpendLogs" (
    request_id text NOT NULL,
    call_type text NOT NULL,
    api_key text DEFAULT ''::text NOT NULL,
    spend double precision DEFAULT 0.0 NOT NULL,
    total_tokens integer DEFAULT 0 NOT NULL,
    prompt_tokens integer DEFAULT 0 NOT NULL,
    completion_tokens integer DEFAULT 0 NOT NULL,
    "startTime" timestamp(3) without time zone NOT NULL,
    "endTime" timestamp(3) without time zone NOT NULL,
    "completionStartTime" timestamp(3) without time zone,
    model text DEFAULT ''::text NOT NULL,
    model_id text DEFAULT ''::text,
    model_group text DEFAULT ''::text,
    custom_llm_provider text DEFAULT ''::text,
    api_base text DEFAULT ''::text,
    "user" text DEFAULT ''::text,
    metadata jsonb DEFAULT '{}'::jsonb,
    cache_hit text DEFAULT ''::text,
    cache_key text DEFAULT ''::text,
    request_tags jsonb DEFAULT '[]'::jsonb,
    team_id text,
    end_user text,
    requester_ip_address text,
    messages jsonb DEFAULT '{}'::jsonb,
    response jsonb DEFAULT '{}'::jsonb,
    session_id text,
    status text,
    proxy_server_request jsonb DEFAULT '{}'::jsonb
);


ALTER TABLE public."LiteLLM_SpendLogs" OWNER TO postgres;

--
-- Name: DailyTagSpend; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."DailyTagSpend" AS
 SELECT jsonb_array_elements_text(request_tags) AS individual_request_tag,
    date("startTime") AS spend_date,
    count(*) AS log_count,
    sum(spend) AS total_spend
   FROM public."LiteLLM_SpendLogs" s
  GROUP BY (jsonb_array_elements_text(request_tags)), (date("startTime"));


ALTER VIEW public."DailyTagSpend" OWNER TO postgres;

--
-- Name: LiteLLM_VerificationToken; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_VerificationToken" (
    token text NOT NULL,
    key_name text,
    key_alias text,
    soft_budget_cooldown boolean DEFAULT false NOT NULL,
    spend double precision DEFAULT 0.0 NOT NULL,
    expires timestamp(3) without time zone,
    models text[],
    aliases jsonb DEFAULT '{}'::jsonb NOT NULL,
    config jsonb DEFAULT '{}'::jsonb NOT NULL,
    user_id text,
    team_id text,
    permissions jsonb DEFAULT '{}'::jsonb NOT NULL,
    max_parallel_requests integer,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    blocked boolean,
    tpm_limit bigint,
    rpm_limit bigint,
    max_budget double precision,
    budget_duration text,
    budget_reset_at timestamp(3) without time zone,
    allowed_cache_controls text[] DEFAULT ARRAY[]::text[],
    allowed_routes text[] DEFAULT ARRAY[]::text[],
    model_spend jsonb DEFAULT '{}'::jsonb NOT NULL,
    model_max_budget jsonb DEFAULT '{}'::jsonb NOT NULL,
    budget_id text,
    organization_id text,
    object_permission_id text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by text,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by text
);


ALTER TABLE public."LiteLLM_VerificationToken" OWNER TO postgres;

--
-- Name: Last30dKeysBySpend; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."Last30dKeysBySpend" AS
 SELECT l.api_key,
    v.key_alias,
    v.key_name,
    sum(l.spend) AS total_spend
   FROM (public."LiteLLM_SpendLogs" l
     LEFT JOIN public."LiteLLM_VerificationToken" v ON ((l.api_key = v.token)))
  WHERE (l."startTime" >= (CURRENT_DATE - '30 days'::interval))
  GROUP BY l.api_key, v.key_alias, v.key_name
  ORDER BY (sum(l.spend)) DESC;


ALTER VIEW public."Last30dKeysBySpend" OWNER TO postgres;

--
-- Name: Last30dModelsBySpend; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."Last30dModelsBySpend" AS
 SELECT model,
    sum(spend) AS total_spend
   FROM public."LiteLLM_SpendLogs"
  WHERE (("startTime" >= (CURRENT_DATE - '30 days'::interval)) AND (model <> ''::text))
  GROUP BY model
  ORDER BY (sum(spend)) DESC;


ALTER VIEW public."Last30dModelsBySpend" OWNER TO postgres;

--
-- Name: Last30dTopEndUsersSpend; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."Last30dTopEndUsersSpend" AS
 SELECT end_user,
    count(*) AS total_events,
    sum(spend) AS total_spend
   FROM public."LiteLLM_SpendLogs"
  WHERE ((end_user <> ''::text) AND (end_user <> USER) AND ("startTime" >= (CURRENT_DATE - '30 days'::interval)))
  GROUP BY end_user
  ORDER BY (sum(spend)) DESC
 LIMIT 100;


ALTER VIEW public."Last30dTopEndUsersSpend" OWNER TO postgres;

--
-- Name: LiteLLM_AuditLog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_AuditLog" (
    id text NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    changed_by text DEFAULT ''::text NOT NULL,
    changed_by_api_key text DEFAULT ''::text NOT NULL,
    action text NOT NULL,
    table_name text NOT NULL,
    object_id text NOT NULL,
    before_value jsonb,
    updated_values jsonb
);


ALTER TABLE public."LiteLLM_AuditLog" OWNER TO postgres;

--
-- Name: LiteLLM_BudgetTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_BudgetTable" (
    budget_id text NOT NULL,
    max_budget double precision,
    soft_budget double precision,
    max_parallel_requests integer,
    tpm_limit bigint,
    rpm_limit bigint,
    model_max_budget jsonb,
    budget_duration text,
    budget_reset_at timestamp(3) without time zone,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by text NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by text NOT NULL
);


ALTER TABLE public."LiteLLM_BudgetTable" OWNER TO postgres;

--
-- Name: LiteLLM_Config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_Config" (
    param_name text NOT NULL,
    param_value jsonb
);


ALTER TABLE public."LiteLLM_Config" OWNER TO postgres;

--
-- Name: LiteLLM_CredentialsTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_CredentialsTable" (
    credential_id text NOT NULL,
    credential_name text NOT NULL,
    credential_values jsonb NOT NULL,
    credential_info jsonb,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by text NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by text NOT NULL
);


ALTER TABLE public."LiteLLM_CredentialsTable" OWNER TO postgres;

--
-- Name: LiteLLM_CronJob; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_CronJob" (
    cronjob_id text NOT NULL,
    pod_id text NOT NULL,
    status public."JobStatus" DEFAULT 'INACTIVE'::public."JobStatus" NOT NULL,
    last_updated timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ttl timestamp(3) without time zone NOT NULL
);


ALTER TABLE public."LiteLLM_CronJob" OWNER TO postgres;

--
-- Name: LiteLLM_DailyTagSpend; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_DailyTagSpend" (
    id text NOT NULL,
    tag text,
    date text NOT NULL,
    api_key text NOT NULL,
    model text NOT NULL,
    model_group text,
    custom_llm_provider text,
    prompt_tokens bigint DEFAULT 0 NOT NULL,
    completion_tokens bigint DEFAULT 0 NOT NULL,
    cache_read_input_tokens bigint DEFAULT 0 NOT NULL,
    cache_creation_input_tokens bigint DEFAULT 0 NOT NULL,
    spend double precision DEFAULT 0.0 NOT NULL,
    api_requests bigint DEFAULT 0 NOT NULL,
    successful_requests bigint DEFAULT 0 NOT NULL,
    failed_requests bigint DEFAULT 0 NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public."LiteLLM_DailyTagSpend" OWNER TO postgres;

--
-- Name: LiteLLM_DailyTeamSpend; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_DailyTeamSpend" (
    id text NOT NULL,
    team_id text,
    date text NOT NULL,
    api_key text NOT NULL,
    model text NOT NULL,
    model_group text,
    custom_llm_provider text,
    prompt_tokens bigint DEFAULT 0 NOT NULL,
    completion_tokens bigint DEFAULT 0 NOT NULL,
    cache_read_input_tokens bigint DEFAULT 0 NOT NULL,
    cache_creation_input_tokens bigint DEFAULT 0 NOT NULL,
    spend double precision DEFAULT 0.0 NOT NULL,
    api_requests bigint DEFAULT 0 NOT NULL,
    successful_requests bigint DEFAULT 0 NOT NULL,
    failed_requests bigint DEFAULT 0 NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public."LiteLLM_DailyTeamSpend" OWNER TO postgres;

--
-- Name: LiteLLM_DailyUserSpend; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_DailyUserSpend" (
    id text NOT NULL,
    user_id text,
    date text NOT NULL,
    api_key text NOT NULL,
    model text NOT NULL,
    model_group text,
    custom_llm_provider text,
    prompt_tokens bigint DEFAULT 0 NOT NULL,
    completion_tokens bigint DEFAULT 0 NOT NULL,
    cache_read_input_tokens bigint DEFAULT 0 NOT NULL,
    cache_creation_input_tokens bigint DEFAULT 0 NOT NULL,
    spend double precision DEFAULT 0.0 NOT NULL,
    api_requests bigint DEFAULT 0 NOT NULL,
    successful_requests bigint DEFAULT 0 NOT NULL,
    failed_requests bigint DEFAULT 0 NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public."LiteLLM_DailyUserSpend" OWNER TO postgres;

--
-- Name: LiteLLM_EndUserTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_EndUserTable" (
    user_id text NOT NULL,
    alias text,
    spend double precision DEFAULT 0.0 NOT NULL,
    allowed_model_region text,
    default_model text,
    budget_id text,
    blocked boolean DEFAULT false NOT NULL
);


ALTER TABLE public."LiteLLM_EndUserTable" OWNER TO postgres;

--
-- Name: LiteLLM_ErrorLogs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_ErrorLogs" (
    request_id text NOT NULL,
    "startTime" timestamp(3) without time zone NOT NULL,
    "endTime" timestamp(3) without time zone NOT NULL,
    api_base text DEFAULT ''::text NOT NULL,
    model_group text DEFAULT ''::text NOT NULL,
    litellm_model_name text DEFAULT ''::text NOT NULL,
    model_id text DEFAULT ''::text NOT NULL,
    request_kwargs jsonb DEFAULT '{}'::jsonb NOT NULL,
    exception_type text DEFAULT ''::text NOT NULL,
    exception_string text DEFAULT ''::text NOT NULL,
    status_code text DEFAULT ''::text NOT NULL
);


ALTER TABLE public."LiteLLM_ErrorLogs" OWNER TO postgres;

--
-- Name: LiteLLM_GuardrailsTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_GuardrailsTable" (
    guardrail_id text NOT NULL,
    guardrail_name text NOT NULL,
    litellm_params jsonb NOT NULL,
    guardrail_info jsonb,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public."LiteLLM_GuardrailsTable" OWNER TO postgres;

--
-- Name: LiteLLM_HealthCheckTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_HealthCheckTable" (
    health_check_id text NOT NULL,
    model_name text NOT NULL,
    model_id text,
    status text NOT NULL,
    healthy_count integer DEFAULT 0 NOT NULL,
    unhealthy_count integer DEFAULT 0 NOT NULL,
    error_message text,
    response_time_ms double precision,
    details jsonb,
    checked_by text,
    checked_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL
);


ALTER TABLE public."LiteLLM_HealthCheckTable" OWNER TO postgres;

--
-- Name: LiteLLM_InvitationLink; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_InvitationLink" (
    id text NOT NULL,
    user_id text NOT NULL,
    is_accepted boolean DEFAULT false NOT NULL,
    accepted_at timestamp(3) without time zone,
    expires_at timestamp(3) without time zone NOT NULL,
    created_at timestamp(3) without time zone NOT NULL,
    created_by text NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    updated_by text NOT NULL
);


ALTER TABLE public."LiteLLM_InvitationLink" OWNER TO postgres;

--
-- Name: LiteLLM_MCPServerTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_MCPServerTable" (
    server_id text NOT NULL,
    alias text,
    description text,
    url text NOT NULL,
    transport text DEFAULT 'sse'::text NOT NULL,
    spec_version text DEFAULT '2025-03-26'::text NOT NULL,
    auth_type text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by text,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by text
);


ALTER TABLE public."LiteLLM_MCPServerTable" OWNER TO postgres;

--
-- Name: LiteLLM_ManagedFileTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_ManagedFileTable" (
    id text NOT NULL,
    unified_file_id text NOT NULL,
    file_object jsonb NOT NULL,
    model_mappings jsonb NOT NULL,
    flat_model_file_ids text[] DEFAULT ARRAY[]::text[],
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by text,
    updated_at timestamp(3) without time zone NOT NULL,
    updated_by text
);


ALTER TABLE public."LiteLLM_ManagedFileTable" OWNER TO postgres;

--
-- Name: LiteLLM_ManagedObjectTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_ManagedObjectTable" (
    id text NOT NULL,
    unified_object_id text NOT NULL,
    model_object_id text NOT NULL,
    file_object jsonb NOT NULL,
    file_purpose text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by text,
    updated_at timestamp(3) without time zone NOT NULL,
    updated_by text
);


ALTER TABLE public."LiteLLM_ManagedObjectTable" OWNER TO postgres;

--
-- Name: LiteLLM_ManagedVectorStoresTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_ManagedVectorStoresTable" (
    vector_store_id text NOT NULL,
    custom_llm_provider text NOT NULL,
    vector_store_name text,
    vector_store_description text,
    vector_store_metadata jsonb,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone NOT NULL,
    litellm_credential_name text
);


ALTER TABLE public."LiteLLM_ManagedVectorStoresTable" OWNER TO postgres;

--
-- Name: LiteLLM_ModelTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_ModelTable" (
    id integer NOT NULL,
    aliases jsonb,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by text NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by text NOT NULL
);


ALTER TABLE public."LiteLLM_ModelTable" OWNER TO postgres;

--
-- Name: LiteLLM_ModelTable_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."LiteLLM_ModelTable_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."LiteLLM_ModelTable_id_seq" OWNER TO postgres;

--
-- Name: LiteLLM_ModelTable_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."LiteLLM_ModelTable_id_seq" OWNED BY public."LiteLLM_ModelTable".id;


--
-- Name: LiteLLM_ObjectPermissionTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_ObjectPermissionTable" (
    object_permission_id text NOT NULL,
    mcp_servers text[] DEFAULT ARRAY[]::text[],
    vector_stores text[] DEFAULT ARRAY[]::text[]
);


ALTER TABLE public."LiteLLM_ObjectPermissionTable" OWNER TO postgres;

--
-- Name: LiteLLM_OrganizationMembership; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_OrganizationMembership" (
    user_id text NOT NULL,
    organization_id text NOT NULL,
    user_role text,
    spend double precision DEFAULT 0.0,
    budget_id text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public."LiteLLM_OrganizationMembership" OWNER TO postgres;

--
-- Name: LiteLLM_OrganizationTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_OrganizationTable" (
    organization_id text NOT NULL,
    organization_alias text NOT NULL,
    budget_id text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    models text[],
    spend double precision DEFAULT 0.0 NOT NULL,
    model_spend jsonb DEFAULT '{}'::jsonb NOT NULL,
    object_permission_id text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by text NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by text NOT NULL
);


ALTER TABLE public."LiteLLM_OrganizationTable" OWNER TO postgres;

--
-- Name: LiteLLM_ProxyModelTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_ProxyModelTable" (
    model_id text NOT NULL,
    model_name text NOT NULL,
    litellm_params jsonb NOT NULL,
    model_info jsonb,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by text NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by text NOT NULL
);


ALTER TABLE public."LiteLLM_ProxyModelTable" OWNER TO postgres;

--
-- Name: LiteLLM_TeamMembership; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_TeamMembership" (
    user_id text NOT NULL,
    team_id text NOT NULL,
    spend double precision DEFAULT 0.0 NOT NULL,
    budget_id text
);


ALTER TABLE public."LiteLLM_TeamMembership" OWNER TO postgres;

--
-- Name: LiteLLM_TeamTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_TeamTable" (
    team_id text NOT NULL,
    team_alias text,
    organization_id text,
    object_permission_id text,
    admins text[],
    members text[],
    members_with_roles jsonb DEFAULT '{}'::jsonb NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    max_budget double precision,
    spend double precision DEFAULT 0.0 NOT NULL,
    models text[],
    max_parallel_requests integer,
    tpm_limit bigint,
    rpm_limit bigint,
    budget_duration text,
    budget_reset_at timestamp(3) without time zone,
    blocked boolean DEFAULT false NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    model_spend jsonb DEFAULT '{}'::jsonb NOT NULL,
    model_max_budget jsonb DEFAULT '{}'::jsonb NOT NULL,
    team_member_permissions text[] DEFAULT ARRAY[]::text[],
    model_id integer
);


ALTER TABLE public."LiteLLM_TeamTable" OWNER TO postgres;

--
-- Name: LiteLLM_UserNotifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_UserNotifications" (
    request_id text NOT NULL,
    user_id text NOT NULL,
    models text[],
    justification text NOT NULL,
    status text NOT NULL
);


ALTER TABLE public."LiteLLM_UserNotifications" OWNER TO postgres;

--
-- Name: LiteLLM_UserTable; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."LiteLLM_UserTable" (
    user_id text NOT NULL,
    user_alias text,
    team_id text,
    sso_user_id text,
    organization_id text,
    object_permission_id text,
    password text,
    teams text[] DEFAULT ARRAY[]::text[],
    user_role text,
    max_budget double precision,
    spend double precision DEFAULT 0.0 NOT NULL,
    user_email text,
    models text[],
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    max_parallel_requests integer,
    tpm_limit bigint,
    rpm_limit bigint,
    budget_duration text,
    budget_reset_at timestamp(3) without time zone,
    allowed_cache_controls text[] DEFAULT ARRAY[]::text[],
    model_spend jsonb DEFAULT '{}'::jsonb NOT NULL,
    model_max_budget jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public."LiteLLM_UserTable" OWNER TO postgres;

--
-- Name: LiteLLM_VerificationTokenView; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."LiteLLM_VerificationTokenView" AS
 SELECT v.token,
    v.key_name,
    v.key_alias,
    v.soft_budget_cooldown,
    v.spend,
    v.expires,
    v.models,
    v.aliases,
    v.config,
    v.user_id,
    v.team_id,
    v.permissions,
    v.max_parallel_requests,
    v.metadata,
    v.blocked,
    v.tpm_limit,
    v.rpm_limit,
    v.max_budget,
    v.budget_duration,
    v.budget_reset_at,
    v.allowed_cache_controls,
    v.allowed_routes,
    v.model_spend,
    v.model_max_budget,
    v.budget_id,
    v.organization_id,
    v.object_permission_id,
    v.created_at,
    v.created_by,
    v.updated_at,
    v.updated_by,
    t.spend AS team_spend,
    t.max_budget AS team_max_budget,
    t.tpm_limit AS team_tpm_limit,
    t.rpm_limit AS team_rpm_limit
   FROM (public."LiteLLM_VerificationToken" v
     LEFT JOIN public."LiteLLM_TeamTable" t ON ((v.team_id = t.team_id)));


ALTER VIEW public."LiteLLM_VerificationTokenView" OWNER TO postgres;

--
-- Name: MonthlyGlobalSpend; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."MonthlyGlobalSpend" AS
 SELECT date("startTime") AS date,
    sum(spend) AS spend
   FROM public."LiteLLM_SpendLogs"
  WHERE ("startTime" >= (CURRENT_DATE - '30 days'::interval))
  GROUP BY (date("startTime"));


ALTER VIEW public."MonthlyGlobalSpend" OWNER TO postgres;

--
-- Name: MonthlyGlobalSpendPerKey; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."MonthlyGlobalSpendPerKey" AS
 SELECT date("startTime") AS date,
    sum(spend) AS spend,
    api_key
   FROM public."LiteLLM_SpendLogs"
  WHERE ("startTime" >= (CURRENT_DATE - '30 days'::interval))
  GROUP BY (date("startTime")), api_key;


ALTER VIEW public."MonthlyGlobalSpendPerKey" OWNER TO postgres;

--
-- Name: MonthlyGlobalSpendPerUserPerKey; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."MonthlyGlobalSpendPerUserPerKey" AS
 SELECT date("startTime") AS date,
    sum(spend) AS spend,
    api_key,
    "user"
   FROM public."LiteLLM_SpendLogs"
  WHERE ("startTime" >= (CURRENT_DATE - '30 days'::interval))
  GROUP BY (date("startTime")), "user", api_key;


ALTER VIEW public."MonthlyGlobalSpendPerUserPerKey" OWNER TO postgres;

--
-- Name: LiteLLM_ModelTable id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_ModelTable" ALTER COLUMN id SET DEFAULT nextval('public."LiteLLM_ModelTable_id_seq"'::regclass);


--
-- Data for Name: LiteLLM_AuditLog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_AuditLog" (id, updated_at, changed_by, changed_by_api_key, action, table_name, object_id, before_value, updated_values) FROM stdin;
\.


--
-- Data for Name: LiteLLM_BudgetTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_BudgetTable" (budget_id, max_budget, soft_budget, max_parallel_requests, tpm_limit, rpm_limit, model_max_budget, budget_duration, budget_reset_at, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: LiteLLM_Config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_Config" (param_name, param_value) FROM stdin;
\.


--
-- Data for Name: LiteLLM_CredentialsTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_CredentialsTable" (credential_id, credential_name, credential_values, credential_info, created_at, created_by, updated_at, updated_by) FROM stdin;
de9734bf-537a-4bd4-80d4-af55c4277d6c	ollama-models	{"api_base": "QxFPjrzh3ePnL6LS+qCTostkTmnJh2iadce8b9OH9d+3Vgf98FnqV+7B5iAZaBSm7xZONVon+EcfM+prXvA2IYMTcV3AGbtoSQ=="}	{"custom_llm_provider": "ollama"}	2025-06-21 17:09:22.762	default_user_id	2025-06-21 17:09:22.762	default_user_id
\.


--
-- Data for Name: LiteLLM_CronJob; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_CronJob" (cronjob_id, pod_id, status, last_updated, ttl) FROM stdin;
\.


--
-- Data for Name: LiteLLM_DailyTagSpend; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_DailyTagSpend" (id, tag, date, api_key, model, model_group, custom_llm_provider, prompt_tokens, completion_tokens, cache_read_input_tokens, cache_creation_input_tokens, spend, api_requests, successful_requests, failed_requests, created_at, updated_at) FROM stdin;
0f5197ed-e8e5-4a04-b023-13e0beba146e	User-Agent: axios	2025-06-21	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	deepseek-r1:14b	ollama/deepseek-r1:14b	ollama	22	520	0	0	0	1	1	0	2025-06-21 17:06:50.561	2025-06-21 17:06:50.561
9e35a0df-d1e7-409d-b54e-af3146a0c7dd	User-Agent: axios/1.8.3	2025-06-21	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	deepseek-r1:14b	ollama/deepseek-r1:14b	ollama	22	520	0	0	0	1	1	0	2025-06-21 17:06:50.561	2025-06-21 17:06:50.561
9c43c761-5f1b-476d-bc6e-f0f92a7ab0b6	User-Agent: axios	2025-06-21	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	mistral-small3.2:latest	ollama/mistral-small3.2:latest	ollama	1057	96	0	0	0	2	2	0	2025-06-21 18:08:19.842	2025-06-21 18:08:59.706
62ebc566-461e-4df9-b9b8-d56f99fb8160	User-Agent: axios/1.8.3	2025-06-21	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	mistral-small3.2:latest	ollama/mistral-small3.2:latest	ollama	1057	96	0	0	0	2	2	0	2025-06-21 18:08:19.842	2025-06-21 18:08:59.706
358afe2c-3196-4097-b7c7-936c577afd66	User-Agent: Mozilla	2025-07-05	8569b3bf513cd8fdf806b2d5dd8e6dcb813fa9a33c87c37583a75770105fab3f	llama3.2:latest	ollama/llama3.2:latest	ollama	92	177	0	0	0	2	2	0	2025-07-05 17:05:49.272	2025-07-05 17:06:29.257
f84afadf-b454-4224-918d-d0a9f3c924d0	User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0	2025-07-05	8569b3bf513cd8fdf806b2d5dd8e6dcb813fa9a33c87c37583a75770105fab3f	llama3.2:latest	ollama/llama3.2:latest	ollama	92	177	0	0	0	2	2	0	2025-07-05 17:05:49.272	2025-07-05 17:06:29.257
fa842cb3-5140-48a1-9146-6d14e985ab91	User-Agent: curl	2025-07-05	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	llama3.2:latest	ollama/llama3.2:latest	ollama	30	10	0	0	0	1	1	0	2025-07-05 17:37:39.253	2025-07-05 17:37:39.253
caec3b47-2b2e-4299-b8f2-e0b801fcca6a	User-Agent: curl/8.5.0	2025-07-05	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	llama3.2:latest	ollama/llama3.2:latest	ollama	30	10	0	0	0	1	1	0	2025-07-05 17:37:39.253	2025-07-05 17:37:39.253
72fc1a7c-143e-480b-bd7b-9a73c450bf41	User-Agent: AsyncOpenAI	2025-10-06	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	llama3.2:latest	ollama/llama3.2:latest	ollama	37387	3718	0	0	0	6	6	0	2025-10-06 21:30:18.66	2025-10-06 22:23:42.346
4f3f2fc3-8dfc-43d7-b2db-a46670739a14	User-Agent: AsyncOpenAI/Python 1.99.2	2025-10-06	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	llama3.2:latest	ollama/llama3.2:latest	ollama	37387	3718	0	0	0	6	6	0	2025-10-06 21:30:18.66	2025-10-06 22:23:42.346
e2316626-dff9-4222-b37b-b23368e0f1c4	User-Agent: AsyncOpenAI	2025-10-06	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	openchat:7b-v3.5-1210	ollama/openchat:7b-v3.5-1210	ollama	72234	10041	0	0	0	40	40	0	2025-10-06 21:30:02.628	2025-10-06 22:24:31.344
bfb5dc70-93a0-4da5-88cf-2d6fd4862fd7	User-Agent: AsyncOpenAI/Python 1.99.2	2025-10-06	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	openchat:7b-v3.5-1210	ollama/openchat:7b-v3.5-1210	ollama	72234	10041	0	0	0	40	40	0	2025-10-06 21:30:02.628	2025-10-06 22:24:31.344
\.


--
-- Data for Name: LiteLLM_DailyTeamSpend; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_DailyTeamSpend" (id, team_id, date, api_key, model, model_group, custom_llm_provider, prompt_tokens, completion_tokens, cache_read_input_tokens, cache_creation_input_tokens, spend, api_requests, successful_requests, failed_requests, created_at, updated_at) FROM stdin;
7440d0d0-9c27-40f0-9c50-c35fd107802d		2025-10-06		ollama/llama3.2:latest	ollama/llama3.2:latest		0	0	0	0	0	3	0	3	2025-10-06 22:23:00.345	2025-10-06 22:23:07.358
0b948973-76ad-4d3d-8d48-586309b40e7a		2025-10-06	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	llama3.2:latest	ollama/llama3.2:latest	ollama	37387	3718	0	0	0	6	6	0	2025-10-06 21:30:18.655	2025-10-06 22:23:42.343
4863e8a0-75a1-45f7-9ad2-b337f8acfb70		2025-10-06	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	openchat:7b-v3.5-1210	ollama/openchat:7b-v3.5-1210	ollama	72234	10041	0	0	0	40	40	0	2025-10-06 21:30:02.623	2025-10-06 22:24:31.342
5a13d18e-e728-4580-be67-5dd68f2ab70d		2025-06-21					0	0	0	0	0	13	0	13	2025-06-21 15:47:21.541	2025-06-21 16:59:49.702
8cd5f6f3-cc13-4fc3-bb0c-a6415a3839cd		2025-06-21		deepseek-r1:14b			0	0	0	0	0	2	0	2	2025-06-21 17:04:49.705	2025-06-21 17:05:19.702
8f38415b-c0b9-4501-9bc5-8fba5cfbc652		2025-06-21	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	deepseek-r1:14b	ollama/deepseek-r1:14b	ollama	22	520	0	0	0	1	1	0	2025-06-21 17:06:50.558	2025-06-21 17:06:50.558
7fbe01b2-14b4-4fc2-a14f-68bb1d16d8ed		2025-06-21		ollama/mistral:latest			0	0	0	0	0	1	0	1	2025-06-21 17:11:49.704	2025-06-21 17:11:49.704
e281faa5-71a8-4011-a575-afbe97f0eb19		2025-06-21		ollama/mistral-small3.2:latest			0	0	0	0	0	1	0	1	2025-06-21 17:50:29.707	2025-06-21 17:50:29.707
998b822b-3ae7-4088-9afa-3867b42dc722		2025-06-21	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	mistral-small3.2:latest	ollama/mistral-small3.2:latest	ollama	1057	96	0	0	0	2	2	0	2025-06-21 18:08:19.795	2025-06-21 18:08:59.703
181f1fb7-ca94-4a3a-a4b5-85a057fb382f		2025-06-23					0	0	0	0	0	2	0	2	2025-06-23 06:55:48.017	2025-06-23 06:55:48.017
c7e3c0b7-9ffd-42a4-8a35-9f4c18aca106	litellm-dashboard	2025-07-05	8569b3bf513cd8fdf806b2d5dd8e6dcb813fa9a33c87c37583a75770105fab3f	llama3.2:latest	ollama/llama3.2:latest	ollama	92	177	0	0	0	2	2	0	2025-07-05 17:05:49.266	2025-07-05 17:06:29.254
9fccfb88-8a13-4630-9944-ce460f2c030b		2025-07-05		ollama/llama3.2			0	0	0	0	0	1	0	1	2025-07-05 17:20:59.992	2025-07-05 17:20:59.992
8285d556-42e1-4093-a4a8-bce5dc268cfc		2025-07-05		ollama/llama2			0	0	0	0	0	2	0	2	2025-07-05 17:35:20.038	2025-07-05 17:36:09.243
f6c33036-b114-495a-ba6c-c1803f912aed		2025-07-05		ollama/llama3.2:latest			0	0	0	0	0	1	0	1	2025-07-05 17:36:39.241	2025-07-05 17:36:39.241
9546a4f6-90e0-46b0-8e30-4148df9552ff		2025-07-05	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	llama3.2:latest	ollama/llama3.2:latest	ollama	30	10	0	0	0	1	1	0	2025-07-05 17:37:39.249	2025-07-05 17:37:39.249
22023f61-2e1f-4a0a-b54e-443d45e3d640		2025-10-06					0	0	0	0	0	4	0	4	2025-10-06 21:28:50.617	2025-10-06 21:29:14.622
\.


--
-- Data for Name: LiteLLM_DailyUserSpend; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_DailyUserSpend" (id, user_id, date, api_key, model, model_group, custom_llm_provider, prompt_tokens, completion_tokens, cache_read_input_tokens, cache_creation_input_tokens, spend, api_requests, successful_requests, failed_requests, created_at, updated_at) FROM stdin;
e544804a-6ddf-4766-afb8-bfeaf0fa39a2	default_user_id	2025-10-06		ollama/llama3.2:latest	ollama/llama3.2:latest		0	0	0	0	0	3	0	3	2025-10-06 22:23:00.34	2025-10-06 22:23:07.353
c42dc061-8f74-4d02-83d8-5258ce4b9eda		2025-06-21					0	0	0	0	0	10	0	10	2025-06-21 15:47:21.528	2025-06-21 16:43:29.691
685e584b-af9d-453d-97b7-f12b7a16a40e	default_user_id	2025-10-06	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	llama3.2:latest	ollama/llama3.2:latest	ollama	37387	3718	0	0	0	6	6	0	2025-10-06 21:30:18.651	2025-10-06 22:23:42.34
8b2ec188-ceeb-4883-9644-5c066270e19c	default_user_id	2025-06-21					0	0	0	0	0	3	0	3	2025-06-21 16:42:19.701	2025-06-21 16:59:49.699
befbf175-fbeb-4aa2-a54e-23c6a5a1ec7b	default_user_id	2025-06-21		deepseek-r1:14b			0	0	0	0	0	2	0	2	2025-06-21 17:04:49.7	2025-06-21 17:05:19.699
6a523004-7810-4a57-928d-3b95ced4ab56	default_user_id	2025-06-21	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	deepseek-r1:14b	ollama/deepseek-r1:14b	ollama	22	520	0	0	0	1	1	0	2025-06-21 17:06:50.554	2025-06-21 17:06:50.554
4976b028-5c70-497b-a45a-6787617905d7	default_user_id	2025-06-21		ollama/mistral:latest			0	0	0	0	0	1	0	1	2025-06-21 17:11:49.7	2025-06-21 17:11:49.7
6b833c50-adf0-4483-91ca-8d161d246616	default_user_id	2025-06-21		ollama/mistral-small3.2:latest			0	0	0	0	0	1	0	1	2025-06-21 17:50:29.703	2025-06-21 17:50:29.703
45decae6-bb45-4145-8b2a-9d5dc79d2f24	default_user_id	2025-06-21	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	mistral-small3.2:latest	ollama/mistral-small3.2:latest	ollama	1057	96	0	0	0	2	2	0	2025-06-21 18:08:19.742	2025-06-21 18:08:59.7
a317a4ff-88e2-459f-bc5e-870e30f206ba		2025-06-23					0	0	0	0	0	2	0	2	2025-06-23 06:55:48.008	2025-06-23 06:55:48.008
d8b9188e-f800-4da1-a409-951185b9acfe	default_user_id	2025-07-05	8569b3bf513cd8fdf806b2d5dd8e6dcb813fa9a33c87c37583a75770105fab3f	llama3.2:latest	ollama/llama3.2:latest	ollama	92	177	0	0	0	2	2	0	2025-07-05 17:05:49.259	2025-07-05 17:06:29.251
42add8d8-1259-4be7-8a52-5b49d1a388e6		2025-07-05		ollama/llama3.2			0	0	0	0	0	1	0	1	2025-07-05 17:20:59.985	2025-07-05 17:20:59.985
4af1301b-cb12-490b-9d2e-b614c956ef96		2025-07-05		ollama/llama2			0	0	0	0	0	2	0	2	2025-07-05 17:35:20.033	2025-07-05 17:36:09.239
a575770c-fea8-4b11-a293-9190b63f9dd4		2025-07-05		ollama/llama3.2:latest			0	0	0	0	0	1	0	1	2025-07-05 17:36:39.238	2025-07-05 17:36:39.238
f88bfa67-adc6-4cab-a14b-8b92ac40e535	default_user_id	2025-07-05	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	llama3.2:latest	ollama/llama3.2:latest	ollama	30	10	0	0	0	1	1	0	2025-07-05 17:37:39.244	2025-07-05 17:37:39.244
30c08fdf-d7c9-4bd2-8ac6-b7a2e5cd62f3		2025-10-06					0	0	0	0	0	4	0	4	2025-10-06 21:28:50.607	2025-10-06 21:29:14.617
300b9745-2fe3-4622-bf6e-d762f1204b7d	default_user_id	2025-10-06	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	openchat:7b-v3.5-1210	ollama/openchat:7b-v3.5-1210	ollama	72234	10041	0	0	0	40	40	0	2025-10-06 21:30:02.619	2025-10-06 22:24:31.339
\.


--
-- Data for Name: LiteLLM_EndUserTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_EndUserTable" (user_id, alias, spend, allowed_model_region, default_model, budget_id, blocked) FROM stdin;
\.


--
-- Data for Name: LiteLLM_ErrorLogs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_ErrorLogs" (request_id, "startTime", "endTime", api_base, model_group, litellm_model_name, model_id, request_kwargs, exception_type, exception_string, status_code) FROM stdin;
\.


--
-- Data for Name: LiteLLM_GuardrailsTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_GuardrailsTable" (guardrail_id, guardrail_name, litellm_params, guardrail_info, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: LiteLLM_HealthCheckTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_HealthCheckTable" (health_check_id, model_name, model_id, status, healthy_count, unhealthy_count, error_message, response_time_ms, details, checked_by, checked_at, created_at, updated_at) FROM stdin;
62bcbcbb-c407-473d-bb47-552c9e94172f	ollama/deepseek-r1:14b	\N	healthy	1	0	\N	19970.87812423706	\N	default_user_id	2025-06-21 16:48:35.688	2025-06-21 16:48:35.688	2025-06-21 16:48:35.688
9ab9463b-24ac-43df-a0a3-9d92089854e4	ollama/deepseek-r1:14b	\N	healthy	1	0	\N	2800.505876541138	\N	default_user_id	2025-06-21 16:49:02.341	2025-06-21 16:49:02.341	2025-06-21 16:49:02.341
ed68e420-3099-4460-853a-d85a67399290	ollama/dolphin-mixtral:latest 	\N	unhealthy	0	1	litellm.APIConnectionError: OllamaException - {"error":"model 'dolphin-mixtral:latest ' not found"}\nstack trace: Traceback (most recent call last):\n  File "/usr/lib/python3.13/site-packages/litellm/llms/custom_httpx/llm_http_handler.py", line 100, in _make_common_async_call\n    response = await async_httpx_client.post(\n               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n    ...<10 lines>...\n    )\n    ^\n  File "/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/logging_utils.py", line 135, in	44.79646682739258	\N	default_user_id	2025-06-21 19:29:49.555	2025-06-21 19:29:49.555	2025-06-21 19:29:49.555
5b0a1896-a651-4dab-a3e9-e7160765d9bc	ollama/nomic-embed-text:latest	\N	unhealthy	0	1	litellm.APIConnectionError: OllamaException - {"error":"\\"nomic-embed-text:latest\\" does not support generate"}\nstack trace: Traceback (most recent call last):\n  File "/usr/lib/python3.13/site-packages/litellm/llms/custom_httpx/llm_http_handler.py", line 100, in _make_common_async_call\n    response = await async_httpx_client.post(\n               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n    ...<10 lines>...\n    )\n    ^\n  File "/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/logging_utils.py", 	50.42028427124023	\N	default_user_id	2025-06-21 19:29:49.556	2025-06-21 19:29:49.556	2025-06-21 19:29:49.556
85ee8d59-b86e-4b71-a77f-4ea9cb0917a8	ollama/dolphin-mixtral:latest 	\N	unhealthy	0	1	litellm.APIConnectionError: OllamaException - {"error":"model 'dolphin-mixtral:latest ' not found"}\nstack trace: Traceback (most recent call last):\n  File "/usr/lib/python3.13/site-packages/litellm/llms/custom_httpx/llm_http_handler.py", line 100, in _make_common_async_call\n    response = await async_httpx_client.post(\n               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n    ...<10 lines>...\n    )\n    ^\n  File "/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/logging_utils.py", line 135, in	15.8843994140625	\N	default_user_id	2025-06-21 19:29:55.809	2025-06-21 19:29:55.809	2025-06-21 19:29:55.809
2eb18c55-4a25-4474-8104-852fd834e3b3	ollama/mistral:latest	\N	healthy	1	0	\N	10587.78595924377	\N	default_user_id	2025-06-21 19:30:00.081	2025-06-21 19:30:00.081	2025-06-21 19:30:00.081
97d15cfd-cd13-4eb6-86ba-43c37ebb2f00	ollama/deepseek-r1:14b	\N	healthy	1	0	\N	25894.82045173645	\N	default_user_id	2025-06-21 19:30:15.394	2025-06-21 19:30:15.394	2025-06-21 19:30:15.394
87124ae2-8d61-412f-9725-8fd2518b649c	ollama/mistral-small3.2:latest	\N	unhealthy	0	1	\N	62429.70323562622	\N	default_user_id	2025-06-21 19:30:51.941	2025-06-21 19:30:51.941	2025-06-21 19:30:51.941
c5921928-c4e1-403c-a88a-7c8e65f62c4e	ollama/mistral-small3.2:latest	\N	healthy	1	0	\N	45977.18930244446	\N	default_user_id	2025-06-22 08:57:28.255	2025-06-22 08:57:28.255	2025-06-22 08:57:28.255
\.


--
-- Data for Name: LiteLLM_InvitationLink; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_InvitationLink" (id, user_id, is_accepted, accepted_at, expires_at, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: LiteLLM_MCPServerTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_MCPServerTable" (server_id, alias, description, url, transport, spec_version, auth_type, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: LiteLLM_ManagedFileTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_ManagedFileTable" (id, unified_file_id, file_object, model_mappings, flat_model_file_ids, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: LiteLLM_ManagedObjectTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_ManagedObjectTable" (id, unified_object_id, model_object_id, file_object, file_purpose, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: LiteLLM_ManagedVectorStoresTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_ManagedVectorStoresTable" (vector_store_id, custom_llm_provider, vector_store_name, vector_store_description, vector_store_metadata, created_at, updated_at, litellm_credential_name) FROM stdin;
\.


--
-- Data for Name: LiteLLM_ModelTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_ModelTable" (id, aliases, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: LiteLLM_ObjectPermissionTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_ObjectPermissionTable" (object_permission_id, mcp_servers, vector_stores) FROM stdin;
\.


--
-- Data for Name: LiteLLM_OrganizationMembership; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_OrganizationMembership" (user_id, organization_id, user_role, spend, budget_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: LiteLLM_OrganizationTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_OrganizationTable" (organization_id, organization_alias, budget_id, metadata, models, spend, model_spend, object_permission_id, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- Data for Name: LiteLLM_ProxyModelTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_ProxyModelTable" (model_id, model_name, litellm_params, model_info, created_at, created_by, updated_at, updated_by) FROM stdin;
23ced0a6-92c8-4602-994e-362b33aa3b7e	ollama/MFDoom/deepseek-r1-tool-calling:14b	{"model": "Md+YnNH+BsU7X+SSW1V9LtikVwx3EIRtcgD32IWYbKIRDz/3ymDRIHX910rW8UELh4uoEzP+U0210aLKePTOYBq/T9YXCQu6o9h2Y7Q+tWvQHA==", "use_litellm_proxy": false, "custom_llm_provider": "qWxjqLFN1KhXJ87DLSXT0j+R3M4vT669K42NmMkDJiKyhaGFO3eQUW+x/AHYHw==", "use_in_pass_through": false, "litellm_credential_name": "55jCYljpzTXtHOc67OXxLaqT5w6mii+owURdiKYTpuHAV+F0Yko2fB13nP2269UpRWkW2Ms=", "merge_reasoning_content_in_choices": false}	{"id": "23ced0a6-92c8-4602-994e-362b33aa3b7e", "db_model": false}	2025-06-23 20:09:34.982	default_user_id	2025-06-23 20:09:34.982	default_user_id
af69ac2d-5c66-4bea-8969-635937134486	ollama/llama3.2:latest	{"model": "ryT4Ds12iRTNNmrfGkEXowadxqW7qcpN3lPqyxdEzWcx8VBeCS1mC5PN9MfUvUqwrHZyV2ByqygG36EtZ60=", "use_litellm_proxy": false, "custom_llm_provider": "caXzS7FEKeasOp0GdikITiQzNo/rh65pf7X9gbItbiEVVPhFEq0QjOtSA3n20Q==", "use_in_pass_through": false, "litellm_credential_name": "7pM8PpTfD1bwYyfIpbWDrcpZwpeg99IXEwp1/UsQf6ZN9bkeqcmZKxWPtAm02enfnAExl7o=", "merge_reasoning_content_in_choices": false}	{"id": "af69ac2d-5c66-4bea-8969-635937134486", "db_model": false}	2025-07-05 17:05:14.962	default_user_id	2025-07-05 17:05:14.962	default_user_id
77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	{"model": "gfwPMwRhNp5dGtrQdqCFckEbPcCt76Ev4nKgVbuWJECLpSb9NJVsk5MQwBLX7HxMCLn2UOhszgMjjMhV1oezLkzPOfU=", "use_litellm_proxy": false, "custom_llm_provider": "7DuHWdxqDdPAGkge4CCTodsJtmmjkwxW4jZ1vIIfJ7/447GmnnDAV1e2hi0dyA==", "use_in_pass_through": false, "litellm_credential_name": "kT6Z9kctBIrOSRyuHvWIVk28D9JkGdya7QVUpDezpiXrADznNyq8AQwI7zjZZAK0hMC1MCY=", "merge_reasoning_content_in_choices": false}	{"id": "77457a69-b559-482e-a47e-e6d6657c383a", "db_model": false}	2025-09-28 06:09:31.43	default_user_id	2025-09-28 06:09:31.43	default_user_id
803397e7-be41-4d11-aa0a-631885845888	ollama/codellama:13b-instruct	{"model": "GlSXYjledIAAvDQ7wEDawvSoM69W196mckZhoNRpZCg4tWQDTW0k+OuQ6THSMUdg5HbyUk0lPvNWopFRLPwEqCPoUm2R", "use_litellm_proxy": false, "custom_llm_provider": "TgtuX3IyOKZkkOqc2cG2rlMFkyHHjsJu1Ywp7mRTrBgJUaobN/qEBGxedQrYDQ==", "use_in_pass_through": false, "litellm_credential_name": "5dX+vEtpLD8LvIcFBJwc+58vCGk5B+Vik3714xbgZY07iOkqqhrGDROZKdSQMvXNIt720A4=", "merge_reasoning_content_in_choices": false}	{"id": "803397e7-be41-4d11-aa0a-631885845888", "db_model": false}	2025-09-28 06:11:27.184	default_user_id	2025-09-28 06:11:27.184	default_user_id
dd8595e7-2f95-4069-9e8c-f1d98c72857b	ollama/qwen2.5-coder:latest	{"model": "FfxURsIN6AzzTbGd6DRw1DQSAOTfpmnnPaz/0Fq0hJi80o2AxRGVkblvEQPFnOgOBcL5c6J0bjK7WwMJJidJlm4Sxg==", "use_litellm_proxy": false, "custom_llm_provider": "O0Ok2E5T/E7ldT5wfNCJv7moZGWf7l/X+c4I9mpWtfMMUjlcgWOx/2ImqldW/w==", "use_in_pass_through": false, "input_cost_per_token": 0.0, "output_cost_per_token": 0.0, "litellm_credential_name": "zdk6H3aGxZontXrJnxFslN3AvKCRNHd32Jve8CHu8Lt+tZUvsgJ1t1DMZam/ugYDUTcqs4o=", "merge_reasoning_content_in_choices": false}	{"id": "dd8595e7-2f95-4069-9e8c-f1d98c72857b", "db_model": true, "access_groups": [], "input_cost_per_token": 0, "output_cost_per_token": 0}	2025-06-23 20:10:53.059	default_user_id	2025-09-28 06:12:54.323	default_user_id
\.


--
-- Data for Name: LiteLLM_SpendLogs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_SpendLogs" (request_id, call_type, api_key, spend, total_tokens, prompt_tokens, completion_tokens, "startTime", "endTime", "completionStartTime", model, model_id, model_group, custom_llm_provider, api_base, "user", metadata, cache_hit, cache_key, request_tags, team_id, end_user, requester_ip_address, messages, response, session_id, status, proxy_server_request) FROM stdin;
63bffb30-2a21-4f05-9f26-19f2b47d51e0			0	0	0	0	2025-06-21 15:47:15.344	2025-06-21 15:47:15.344	2025-06-21 15:47:15.343							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": null, "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 577, in _user_api_key_auth_builder\\n    raise Exception(\\"No api key passed in.\\")\\n", "error_code": "", "error_class": "Exception", "llm_provider": "", "error_message": "No api key passed in."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	55f667a3-50cc-46c1-8af3-35615ffa3bbf	failure	{}
3deb519b-48a0-4d57-9bc3-464a0d695543			0	0	0	0	2025-06-21 16:11:19.369	2025-06-21 16:11:19.369	2025-06-21 16:11:19.369							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": null, "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 577, in _user_api_key_auth_builder\\n    raise Exception(\\"No api key passed in.\\")\\n", "error_code": "", "error_class": "Exception", "llm_provider": "", "error_message": "No api key passed in."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	c4e0f5bf-362b-403f-812c-8f3944df44f4	failure	{}
af256733-e171-451a-b68a-9ef7bc8d6eaf			0	0	0	0	2025-06-21 16:12:03.931	2025-06-21 16:12:03.931	2025-06-21 16:12:03.93							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": null, "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 577, in _user_api_key_auth_builder\\n    raise Exception(\\"No api key passed in.\\")\\n", "error_code": "", "error_class": "Exception", "llm_provider": "", "error_message": "No api key passed in."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	317f63fc-4536-489e-88b9-8634d14256b4	failure	{}
a6d57a64-ba73-47ae-aada-ed0a83ef742c			0	0	0	0	2025-06-21 16:13:06.696	2025-06-21 16:13:06.696	2025-06-21 16:13:06.696							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": null, "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 577, in _user_api_key_auth_builder\\n    raise Exception(\\"No api key passed in.\\")\\n", "error_code": "", "error_class": "Exception", "llm_provider": "", "error_message": "No api key passed in."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	4d10dee4-1e59-4bf3-933a-e47d9598aaba	failure	{}
6e2f7492-2321-4def-9c3b-0674f389e01a			0	0	0	0	2025-06-21 16:17:55.604	2025-06-21 16:17:55.604	2025-06-21 16:17:55.603							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": null, "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 577, in _user_api_key_auth_builder\\n    raise Exception(\\"No api key passed in.\\")\\n", "error_code": "", "error_class": "Exception", "llm_provider": "", "error_message": "No api key passed in."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	a96a2e7d-c1ba-4c32-81f9-b87dedd2e2d6	failure	{}
3654726c-dd56-4ffc-af09-8cdfad2c565d			0	0	0	0	2025-06-21 16:21:33.397	2025-06-21 16:21:33.397	2025-06-21 16:21:33.397							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": null, "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 577, in _user_api_key_auth_builder\\n    raise Exception(\\"No api key passed in.\\")\\n", "error_code": "", "error_class": "Exception", "llm_provider": "", "error_message": "No api key passed in."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	26ec0682-bf34-435b-8051-6749ad04184a	failure	{}
83f7f90f-e88e-4e1b-b3e1-363b23075dae			0	0	0	0	2025-06-21 16:26:22.471	2025-06-21 16:26:22.471	2025-06-21 16:26:22.47							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "P0-EfXcv9jCX", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 779, in _user_api_key_auth_builder\\n    assert api_key.startswith(\\n           ~~~~~~~~~~~~~~~~~~^\\n        \\"sk-\\"\\n        ^^^^^\\n    ), \\"LiteLLM Virtual Key expected. Received={}, expected to start with 'sk-'.\\".format(\\n    ^\\n", "error_code": "", "error_class": "AssertionError", "llm_provider": "", "error_message": "LiteLLM Virtual Key expected. Received=P0-EfXcv9jCX, expected to start with 'sk-'."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	ba867e1a-82b7-4176-932c-f4e03c39424c	failure	{}
59338ea9-d53a-447f-b961-4847c09877f8			0	0	0	0	2025-06-21 16:29:17.672	2025-06-21 16:29:17.672	2025-06-21 16:29:17.672							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "P0-EfXcv9jCX", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 779, in _user_api_key_auth_builder\\n    assert api_key.startswith(\\n           ~~~~~~~~~~~~~~~~~~^\\n        \\"sk-\\"\\n        ^^^^^\\n    ), \\"LiteLLM Virtual Key expected. Received={}, expected to start with 'sk-'.\\".format(\\n    ^\\n", "error_code": "", "error_class": "AssertionError", "llm_provider": "", "error_message": "LiteLLM Virtual Key expected. Received=P0-EfXcv9jCX, expected to start with 'sk-'."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	43fecac1-5fba-495d-bd02-928ea91d6900	failure	{}
516c6bbf-4c0f-4355-9728-51af6b5304a0			0	0	0	0	2025-06-21 16:41:03.546	2025-06-21 16:41:03.546	2025-06-21 16:41:03.545							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 580, in _user_api_key_auth_builder\\n    raise Exception(\\n        f\\"Malformed API Key passed in. Ensure Key has `Bearer ` prefix. Passed in: {passed_in_key}\\"\\n    )\\n", "error_code": "", "error_class": "Exception", "llm_provider": "", "error_message": "Malformed API Key passed in. Ensure Key has `Bearer ` prefix. Passed in: x-litellm-api-key: P0-EfXcv9jCX"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	280c347a-70a2-484d-a686-6ee178aeada2	failure	{}
d62f1285-6138-4619-ad03-a2015f6f5482			0	0	0	0	2025-06-21 16:42:12.075	2025-06-21 16:42:12.075	2025-06-21 16:42:12.075						default_user_id	{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/proxy_server.py\\", line 3648, in chat_completion\\n    return await base_llm_response_processor.base_process_llm_request(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<16 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/common_request_processing.py\\", line 386, in base_process_llm_request\\n    llm_call = await route_request(\\n               ^^^^^^^^^^^^^^^^^^^^\\n    ...<4 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/route_llm_request.py\\", line 153, in route_request\\n    raise ProxyModelNotFoundError(\\n    ...<2 lines>...\\n    )\\n", "error_code": "400", "error_class": "ProxyModelNotFoundError", "llm_provider": "", "error_message": "400: {'error': '/chat/completions: Invalid model name passed in model=None. Call `/v1/models` to view available models for your key.'}"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]				{}	{}	630a850c-6c05-48e3-a04b-467b145e491f	failure	{}
b4d7509e-7ad2-42dd-a82d-38c88fc97ae9			0	0	0	0	2025-06-21 16:43:22.307	2025-06-21 16:43:22.307	2025-06-21 16:43:22.307							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 580, in _user_api_key_auth_builder\\n    raise Exception(\\n        f\\"Malformed API Key passed in. Ensure Key has `Bearer ` prefix. Passed in: {passed_in_key}\\"\\n    )\\n", "error_code": "", "error_class": "Exception", "llm_provider": "", "error_message": "Malformed API Key passed in. Ensure Key has `Bearer ` prefix. Passed in: x-litellm-api-key: P0-EfXcv9jCX"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	d93387e7-4b94-4931-add4-fe99d831904e	failure	{}
42214c2e-f846-497e-b1a8-bec5da9b0acd			0	0	0	0	2025-06-21 16:44:54.229	2025-06-21 16:44:54.229	2025-06-21 16:44:54.228						default_user_id	{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/proxy_server.py\\", line 3648, in chat_completion\\n    return await base_llm_response_processor.base_process_llm_request(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<16 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/common_request_processing.py\\", line 386, in base_process_llm_request\\n    llm_call = await route_request(\\n               ^^^^^^^^^^^^^^^^^^^^\\n    ...<4 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/route_llm_request.py\\", line 153, in route_request\\n    raise ProxyModelNotFoundError(\\n    ...<2 lines>...\\n    )\\n", "error_code": "400", "error_class": "ProxyModelNotFoundError", "llm_provider": "", "error_message": "400: {'error': '/chat/completions: Invalid model name passed in model=None. Call `/v1/models` to view available models for your key.'}"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]				{}	{}	d3518233-3bc3-4da1-ac9b-1503bb713f4d	failure	{}
456fe0d6-0759-4206-b9a3-00df0aa827b5			0	0	0	0	2025-06-21 16:59:43.845	2025-06-21 16:59:43.845	2025-06-21 16:59:43.844						default_user_id	{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/proxy_server.py\\", line 3648, in chat_completion\\n    return await base_llm_response_processor.base_process_llm_request(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<16 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/common_request_processing.py\\", line 386, in base_process_llm_request\\n    llm_call = await route_request(\\n               ^^^^^^^^^^^^^^^^^^^^\\n    ...<4 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/route_llm_request.py\\", line 153, in route_request\\n    raise ProxyModelNotFoundError(\\n    ...<2 lines>...\\n    )\\n", "error_code": "400", "error_class": "ProxyModelNotFoundError", "llm_provider": "", "error_message": "400: {'error': '/chat/completions: Invalid model name passed in model=None. Call `/v1/models` to view available models for your key.'}"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]				{}	{}	e9c3b630-dce3-4228-b512-db9b6c76d10d	failure	{}
0d276b8e-27fb-4f97-8ad1-0cd84a0f5823			0	0	0	0	2025-06-21 17:04:41.254	2025-06-21 17:04:41.254	2025-06-21 17:04:41.253	deepseek-r1:14b					default_user_id	{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/proxy_server.py\\", line 3648, in chat_completion\\n    return await base_llm_response_processor.base_process_llm_request(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<16 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/common_request_processing.py\\", line 386, in base_process_llm_request\\n    llm_call = await route_request(\\n               ^^^^^^^^^^^^^^^^^^^^\\n    ...<4 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/route_llm_request.py\\", line 153, in route_request\\n    raise ProxyModelNotFoundError(\\n    ...<2 lines>...\\n    )\\n", "error_code": "400", "error_class": "ProxyModelNotFoundError", "llm_provider": "", "error_message": "400: {'error': '/chat/completions: Invalid model name passed in model=deepseek-r1:14b. Call `/v1/models` to view available models for your key.'}"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]				{}	{}	4d77c3f7-e509-474f-867d-e737789c8733	failure	{}
96d67ab4-f65e-4e2e-8998-5d5c1a36be1a			0	0	0	0	2025-06-21 17:05:18.315	2025-06-21 17:05:18.315	2025-06-21 17:05:18.315	deepseek-r1:14b					default_user_id	{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/proxy_server.py\\", line 3648, in chat_completion\\n    return await base_llm_response_processor.base_process_llm_request(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<16 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/common_request_processing.py\\", line 386, in base_process_llm_request\\n    llm_call = await route_request(\\n               ^^^^^^^^^^^^^^^^^^^^\\n    ...<4 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/route_llm_request.py\\", line 153, in route_request\\n    raise ProxyModelNotFoundError(\\n    ...<2 lines>...\\n    )\\n", "error_code": "400", "error_class": "ProxyModelNotFoundError", "llm_provider": "", "error_message": "400: {'error': '/chat/completions: Invalid model name passed in model=deepseek-r1:14b. Call `/v1/models` to view available models for your key.'}"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]				{}	{}	4c942053-4fbe-474a-8262-1aace0ee0112	failure	{}
chatcmpl-b3e273c1-5833-423e-9d19-5c82f0ed7591	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	542	22	520	2025-06-21 17:06:03.174	2025-06-21 17:06:41.542	2025-06-21 17:06:41.541	deepseek-r1:14b	b9a811f4-76b6-4b62-8188-b1ba7bc55d3e	ollama/deepseek-r1:14b	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 542, "prompt_tokens": 22, "completion_tokens": 520, "prompt_tokens_details": null, "completion_tokens_details": null}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "ollama/deepseek-r1:14b", "model_map_value": null}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": null}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	None	Cache OFF	["User-Agent: axios", "User-Agent: axios/1.8.3"]				{}	{}	80106165-0018-4567-8d0b-b9322cbc845d	success	{}
924b198d-1ef0-4b4f-a9f5-b83519de380b			0	0	0	0	2025-06-21 17:11:45.256	2025-06-21 17:11:45.256	2025-06-21 17:11:45.255	ollama/mistral:latest					default_user_id	{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/proxy_server.py\\", line 3648, in chat_completion\\n    return await base_llm_response_processor.base_process_llm_request(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<16 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/common_request_processing.py\\", line 386, in base_process_llm_request\\n    llm_call = await route_request(\\n               ^^^^^^^^^^^^^^^^^^^^\\n    ...<4 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/route_llm_request.py\\", line 153, in route_request\\n    raise ProxyModelNotFoundError(\\n    ...<2 lines>...\\n    )\\n", "error_code": "400", "error_class": "ProxyModelNotFoundError", "llm_provider": "", "error_message": "400: {'error': '/chat/completions: Invalid model name passed in model=ollama/mistral:latest. Call `/v1/models` to view available models for your key.'}"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]				{}	{}	3b9bc13c-577e-4cfd-99c7-1a7d1f9ffa49	failure	{}
005972fa-ba8a-4fc2-96d9-3992eabbad9f			0	0	0	0	2025-06-21 17:50:22.409	2025-06-21 17:50:22.409	2025-06-21 17:50:22.409	ollama/mistral-small3.2:latest					default_user_id	{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/proxy_server.py\\", line 3648, in chat_completion\\n    return await base_llm_response_processor.base_process_llm_request(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<16 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/common_request_processing.py\\", line 386, in base_process_llm_request\\n    llm_call = await route_request(\\n               ^^^^^^^^^^^^^^^^^^^^\\n    ...<4 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/route_llm_request.py\\", line 153, in route_request\\n    raise ProxyModelNotFoundError(\\n    ...<2 lines>...\\n    )\\n", "error_code": "400", "error_class": "ProxyModelNotFoundError", "llm_provider": "", "error_message": "400: {'error': '/chat/completions: Invalid model name passed in model=ollama/mistral-small3.2:latest. Call `/v1/models` to view available models for your key.'}"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]				{}	{}	0a80ba38-d30b-423d-912e-6cd00de6ed7e	failure	{}
chatcmpl-27e15d99-3d05-4024-9930-e4fc80340ca8	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	540	526	14	2025-06-21 18:07:49.714	2025-06-21 18:08:02.311	2025-06-21 18:08:02.311	mistral-small3.2:latest	7646dd70-26fb-4fd8-b5fa-8b8fc0d114a7	ollama/mistral-small3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 540, "prompt_tokens": 526, "completion_tokens": 14, "prompt_tokens_details": null, "completion_tokens_details": null}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "ollama/mistral-small3.2:latest", "model_map_value": null}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": null}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	None	Cache OFF	["User-Agent: axios", "User-Agent: axios/1.8.3"]				{}	{}	84f46681-771a-4632-98d2-e25a97943498	success	{}
chatcmpl-763b6480-995e-4067-9895-7e6948aa5692	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	613	531	82	2025-06-21 18:08:42.884	2025-06-21 18:08:51.05	2025-06-21 18:08:51.05	mistral-small3.2:latest	7646dd70-26fb-4fd8-b5fa-8b8fc0d114a7	ollama/mistral-small3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 613, "prompt_tokens": 531, "completion_tokens": 82, "prompt_tokens_details": null, "completion_tokens_details": null}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "ollama/mistral-small3.2:latest", "model_map_value": null}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": null}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	None	Cache OFF	["User-Agent: axios", "User-Agent: axios/1.8.3"]				{}	{}	71bb62eb-409e-4b4c-8780-fe5a09ca18fc	success	{}
3a728589-fb33-40c2-ba56-1ac54ccdb3a1			0	0	0	0	2025-06-23 06:55:47.48	2025-06-23 06:55:47.48	2025-06-23 06:55:47.48							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "37a29590f21669e38e1fe4af8a9718f7a0cc2c180623ec1a3a85021604b2ffee", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/starlette/_exception_handler.py\\", line 42, in wrapped_app\\n    await app(scope, receive, sender)\\n  File \\"/usr/lib/python3.13/site-packages/starlette/routing.py\\", line 73, in app\\n    response = await f(request)\\n               ^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/fastapi/routing.py\\", line 291, in app\\n    solved_result = await solve_dependencies(\\n                    ^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<6 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/fastapi/dependencies/utils.py\\", line 638, in solve_dependencies\\n    solved = await call(**solved_result.values)\\n             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 1141, in user_api_key_auth\\n    user_api_key_auth_obj = await _user_api_key_auth_builder(\\n                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<8 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 1108, in _user_api_key_auth_builder\\n    return await UserAPIKeyAuthExceptionHandler._handle_authentication_error(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<6 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/auth_exception_handler.py\\", line 118, in _handle_authentication_error\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 962, in _user_api_key_auth_builder\\n    raise ProxyException(\\n    ...<4 lines>...\\n    )\\n", "error_code": "", "error_class": "ProxyException", "llm_provider": "", "error_message": ""}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	4e825edd-2292-4ab1-81de-aba22783c8a3	failure	{}
2f6cc678-b622-4671-837f-13c37c157725			0	0	0	0	2025-06-23 06:55:47.49	2025-06-23 06:55:47.49	2025-06-23 06:55:47.489							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "37a29590f21669e38e1fe4af8a9718f7a0cc2c180623ec1a3a85021604b2ffee", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/starlette/_exception_handler.py\\", line 42, in wrapped_app\\n    await app(scope, receive, sender)\\n  File \\"/usr/lib/python3.13/site-packages/starlette/routing.py\\", line 73, in app\\n    response = await f(request)\\n               ^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/fastapi/routing.py\\", line 291, in app\\n    solved_result = await solve_dependencies(\\n                    ^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<6 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/fastapi/dependencies/utils.py\\", line 638, in solve_dependencies\\n    solved = await call(**solved_result.values)\\n             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 1141, in user_api_key_auth\\n    user_api_key_auth_obj = await _user_api_key_auth_builder(\\n                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<8 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 1108, in _user_api_key_auth_builder\\n    return await UserAPIKeyAuthExceptionHandler._handle_authentication_error(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<6 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/auth_exception_handler.py\\", line 118, in _handle_authentication_error\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 962, in _user_api_key_auth_builder\\n    raise ProxyException(\\n    ...<4 lines>...\\n    )\\n", "error_code": "", "error_class": "ProxyException", "llm_provider": "", "error_message": ""}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	a9b30b54-5d16-46f6-9677-8805c56cf1da	failure	{}
chatcmpl-6f15e0f6-cf50-4108-b638-bacdf054d8aa	acompletion	8569b3bf513cd8fdf806b2d5dd8e6dcb813fa9a33c87c37583a75770105fab3f	0	40	30	10	2025-07-05 17:05:43.921	2025-07-05 17:05:44.068	2025-07-05 17:05:43.999	llama3.2:latest	af69ac2d-5c66-4bea-8969-635937134486	ollama/llama3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 40, "prompt_tokens": 30, "completion_tokens": 10, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "8569b3bf513cd8fdf806b2d5dd8e6dcb813fa9a33c87c37583a75770105fab3f", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": "litellm-dashboard", "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "llama3.2:latest", "model_map_value": null}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: Mozilla", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0"]	litellm-dashboard			{}	{}	738740d5-17c3-404a-b740-f2422b222429	success	{}
chatcmpl-eaac9f16-6620-4252-af3e-b416ec0d170e	acompletion	8569b3bf513cd8fdf806b2d5dd8e6dcb813fa9a33c87c37583a75770105fab3f	0	229	62	167	2025-07-05 17:06:26.486	2025-07-05 17:06:27.949	2025-07-05 17:06:26.55	llama3.2:latest	af69ac2d-5c66-4bea-8969-635937134486	ollama/llama3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 229, "prompt_tokens": 62, "completion_tokens": 167, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "8569b3bf513cd8fdf806b2d5dd8e6dcb813fa9a33c87c37583a75770105fab3f", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": "litellm-dashboard", "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "llama3.2:latest", "model_map_value": null}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: Mozilla", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0"]	litellm-dashboard			{}	{}	738740d5-17c3-404a-b740-f2422b222429	success	{}
312db69f-fc5a-456e-a2c5-9d94f0ad4666			0	0	0	0	2025-07-05 17:20:58.297	2025-07-05 17:20:58.297	2025-07-05 17:20:58.296	ollama/llama3.2						{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": null, "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 577, in _user_api_key_auth_builder\\n    raise Exception(\\"No api key passed in.\\")\\n", "error_code": "", "error_class": "Exception", "llm_provider": "", "error_message": "No api key passed in."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	081ff6c2-a099-4b4e-a410-ce55ceb539b3	failure	{}
572e2c9f-9860-457c-920e-2ef81cf848f7			0	0	0	0	2025-07-05 17:35:18.863	2025-07-05 17:35:18.863	2025-07-05 17:35:18.863	ollama/llama2						{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "YOUR_LITELLM_API_KEY", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 779, in _user_api_key_auth_builder\\n    assert api_key.startswith(\\n           ~~~~~~~~~~~~~~~~~~^\\n        \\"sk-\\"\\n        ^^^^^\\n    ), \\"LiteLLM Virtual Key expected. Received={}, expected to start with 'sk-'.\\".format(\\n    ^\\n", "error_code": "", "error_class": "AssertionError", "llm_provider": "", "error_message": "LiteLLM Virtual Key expected. Received=YOUR_LITELLM_API_KEY, expected to start with 'sk-'."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	f570d54d-c65c-4b55-b690-ef57f25ec067	failure	{}
2e99775f-db80-47cb-9046-ace15247a1e8			0	0	0	0	2025-07-05 17:36:08.229	2025-07-05 17:36:08.229	2025-07-05 17:36:08.229	ollama/llama2						{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "P0-EfXcv9jCX", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 779, in _user_api_key_auth_builder\\n    assert api_key.startswith(\\n           ~~~~~~~~~~~~~~~~~~^\\n        \\"sk-\\"\\n        ^^^^^\\n    ), \\"LiteLLM Virtual Key expected. Received={}, expected to start with 'sk-'.\\".format(\\n    ^\\n", "error_code": "", "error_class": "AssertionError", "llm_provider": "", "error_message": "LiteLLM Virtual Key expected. Received=P0-EfXcv9jCX, expected to start with 'sk-'."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	540e4da4-e75d-4d4f-bcfc-0312d62ba8aa	failure	{}
408269df-1f34-4890-9063-614bb89f767b			0	0	0	0	2025-07-05 17:36:29.963	2025-07-05 17:36:29.963	2025-07-05 17:36:29.962	ollama/llama3.2:latest						{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "P0-EfXcv9jCX", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 779, in _user_api_key_auth_builder\\n    assert api_key.startswith(\\n           ~~~~~~~~~~~~~~~~~~^\\n        \\"sk-\\"\\n        ^^^^^\\n    ), \\"LiteLLM Virtual Key expected. Received={}, expected to start with 'sk-'.\\".format(\\n    ^\\n", "error_code": "", "error_class": "AssertionError", "llm_provider": "", "error_message": "LiteLLM Virtual Key expected. Received=P0-EfXcv9jCX, expected to start with 'sk-'."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	fb3bc9db-bcf6-4512-80aa-c0c258a7a902	failure	{}
chatcmpl-bbabb580-ed9c-4a71-af29-1c07743cec4c	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	40	30	10	2025-07-05 17:37:27.639	2025-07-05 17:37:32.51	2025-07-05 17:37:32.509	llama3.2:latest	af69ac2d-5c66-4bea-8969-635937134486	ollama/llama3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 40, "prompt_tokens": 30, "completion_tokens": 10, "prompt_tokens_details": null, "completion_tokens_details": null}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "ollama/llama3.2:latest", "model_map_value": null}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": null}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	None	Cache OFF	["User-Agent: curl", "User-Agent: curl/8.5.0"]				{}	{}	f300199d-ba5c-4026-979a-984685ff223b	success	{}
fc725f51-7649-45e2-b36a-7512bc6364a2			0	0	0	0	2025-10-06 21:28:43.03	2025-10-06 21:28:43.03	2025-10-06 21:28:43.029							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": null, "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 577, in _user_api_key_auth_builder\\n    raise Exception(\\"No api key passed in.\\")\\n", "error_code": "", "error_class": "Exception", "llm_provider": "", "error_message": "No api key passed in."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	9365b901-34b5-463f-9bce-dda49a8896ea	failure	{}
1a00d110-5cdd-47cc-bc76-eca73b509eac			0	0	0	0	2025-10-06 21:28:50.971	2025-10-06 21:28:50.971	2025-10-06 21:28:50.971							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "88dc28d0f030c55ed4ab77ed8faf098196cb1c05df778539800c9f1243fe6b4b", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/starlette/_exception_handler.py\\", line 42, in wrapped_app\\n    await app(scope, receive, sender)\\n  File \\"/usr/lib/python3.13/site-packages/starlette/routing.py\\", line 73, in app\\n    response = await f(request)\\n               ^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/fastapi/routing.py\\", line 291, in app\\n    solved_result = await solve_dependencies(\\n                    ^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<6 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/fastapi/dependencies/utils.py\\", line 638, in solve_dependencies\\n    solved = await call(**solved_result.values)\\n             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 1141, in user_api_key_auth\\n    user_api_key_auth_obj = await _user_api_key_auth_builder(\\n                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<8 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 1108, in _user_api_key_auth_builder\\n    return await UserAPIKeyAuthExceptionHandler._handle_authentication_error(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<6 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/auth_exception_handler.py\\", line 118, in _handle_authentication_error\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 807, in _user_api_key_auth_builder\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 795, in _user_api_key_auth_builder\\n    valid_token = await get_key_object(\\n                  ^^^^^^^^^^^^^^^^^^^^^\\n    ...<5 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/db/log_db_metrics.py\\", line 99, in wrapper\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/db/log_db_metrics.py\\", line 42, in wrapper\\n    result = await func(*args, **kwargs)\\n             ^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/auth_checks.py\\", line 1087, in get_key_object\\n    raise ProxyException(\\n    ...<6 lines>...\\n    )\\n", "error_code": "", "error_class": "ProxyException", "llm_provider": "", "error_message": ""}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	f2e8c12c-27e4-42ab-acca-ecd474e8f145	failure	{}
48c476ef-f6df-41b5-90fd-724f9025f9a7			0	0	0	0	2025-10-06 21:28:56.161	2025-10-06 21:28:56.161	2025-10-06 21:28:56.16							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "P0-EfXcv9jCX", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 779, in _user_api_key_auth_builder\\n    assert api_key.startswith(\\n           ~~~~~~~~~~~~~~~~~~^\\n        \\"sk-\\"\\n        ^^^^^\\n    ), \\"LiteLLM Virtual Key expected. Received={}, expected to start with 'sk-'.\\".format(\\n    ^\\n", "error_code": "", "error_class": "AssertionError", "llm_provider": "", "error_message": "LiteLLM Virtual Key expected. Received=P0-EfXcv9jCX, expected to start with 'sk-'."}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	5f67d37c-3c2f-4f7d-9296-84fc4ace7179	failure	{}
fdbde0ab-e5bb-4206-b7fa-c7616a6c3e0b			0	0	0	0	2025-10-06 21:28:59.433	2025-10-06 21:28:59.433	2025-10-06 21:28:59.433							{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "b29de98af56819606c36e5993b664d2fa796778017d0041b9690ec25c94d26ff", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/starlette/_exception_handler.py\\", line 42, in wrapped_app\\n    await app(scope, receive, sender)\\n  File \\"/usr/lib/python3.13/site-packages/starlette/routing.py\\", line 73, in app\\n    response = await f(request)\\n               ^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/fastapi/routing.py\\", line 291, in app\\n    solved_result = await solve_dependencies(\\n                    ^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<6 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/fastapi/dependencies/utils.py\\", line 638, in solve_dependencies\\n    solved = await call(**solved_result.values)\\n             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 1141, in user_api_key_auth\\n    user_api_key_auth_obj = await _user_api_key_auth_builder(\\n                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<8 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 1108, in _user_api_key_auth_builder\\n    return await UserAPIKeyAuthExceptionHandler._handle_authentication_error(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<6 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/auth_exception_handler.py\\", line 118, in _handle_authentication_error\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/auth/user_api_key_auth.py\\", line 962, in _user_api_key_auth_builder\\n    raise ProxyException(\\n    ...<4 lines>...\\n    )\\n", "error_code": "", "error_class": "ProxyException", "llm_provider": "", "error_message": ""}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "user_api_key_team_id": null, "user_api_key_user_id": null, "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]			\N	{}	{}	8ee6e5b3-df99-4624-bff4-4740f6af3ea8	failure	{}
chatcmpl-7ccb642c-73fd-4608-bbd3-e5231084873b	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	410	405	5	2025-10-06 21:29:49.665	2025-10-06 21:29:59.16	2025-10-06 21:29:59.099	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 410, "prompt_tokens": 405, "completion_tokens": 5, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	725d4382-134f-40ce-b5db-fa4e020aea2c	success	{}
chatcmpl-766afbee-3a7f-4f51-9d3a-1221cbf5b1c2	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	506	504	2	2025-10-06 21:29:49.647	2025-10-06 21:29:59.47	2025-10-06 21:29:59.451	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 506, "prompt_tokens": 504, "completion_tokens": 2, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	e98c0a03-bcbe-4bfb-b9dc-7b0852a89e6c	success	{}
chatcmpl-619d13e0-22bf-43ff-a8ba-fed5d0d0d016	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	4405	4096	309	2025-10-06 21:29:59.508	2025-10-06 21:30:13.213	2025-10-06 21:30:08.257	llama3.2:latest	7f6e579f60c2b777101210dad6171eb598f86e47feed3b2855c242bfd4018d32	ollama/llama3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 4405, "prompt_tokens": 4096, "completion_tokens": 309, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "llama3.2:latest", "model_map_value": {"key": "ollama/llama3.2:latest", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	724e16d7-0849-4a91-bf3d-aa09bc92ab56	success	{}
chatcmpl-67c88cc0-7a08-4e1b-a47d-2b92b2983b0a	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1626	1234	392	2025-10-06 21:30:13.306	2025-10-06 21:30:28.689	2025-10-06 21:30:21.194	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1626, "prompt_tokens": 1234, "completion_tokens": 392, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	42d0c381-8826-4d2d-bf0d-b48f800b7101	success	{}
chatcmpl-526590e4-a2e2-40f6-92fb-07095933f363	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1331	1152	179	2025-10-06 21:30:13.309	2025-10-06 21:30:32.066	2025-10-06 21:30:29.43	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1331, "prompt_tokens": 1152, "completion_tokens": 179, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	32efff5d-923e-4db1-9b9d-108fffc6f0b0	success	{}
chatcmpl-525d6d9c-721d-43cf-920b-c27c4fa69eed	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	672	645	27	2025-10-06 21:30:28.732	2025-10-06 21:30:32.808	2025-10-06 21:30:32.448	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 672, "prompt_tokens": 645, "completion_tokens": 27, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	c1a2cc7c-6038-43c2-9383-fd0aa4847098	success	{}
chatcmpl-e1c14a65-3982-492f-8ec7-e8fac9831d3d	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	540	531	9	2025-10-06 21:30:32.089	2025-10-06 21:30:32.954	2025-10-06 21:30:32.841	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 540, "prompt_tokens": 531, "completion_tokens": 9, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	5d71cbea-fdb5-4ffb-9519-99688bf152ff	success	{}
chatcmpl-a882bf26-c8ad-48f7-bae1-81ede1a287fb	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1302	937	365	2025-10-06 21:54:26.378	2025-10-06 21:54:38.872	2025-10-06 21:54:33.47	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1302, "prompt_tokens": 937, "completion_tokens": 365, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	f292f6f1-12df-4ee6-bc0d-f11f60d2a806	success	{}
chatcmpl-27d45cab-be69-4539-b379-d107e7efe485	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	845	841	4	2025-10-06 21:54:26.381	2025-10-06 21:54:39.441	2025-10-06 21:54:39.385	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 845, "prompt_tokens": 841, "completion_tokens": 4, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	a258934e-234a-4b56-a7a8-9963c46ed6d7	success	{}
chatcmpl-a20ba992-eda3-42dd-9266-a93712d14c45	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1227	1223	4	2025-10-06 21:54:39.09	2025-10-06 21:54:40.289	2025-10-06 21:54:40.242	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1227, "prompt_tokens": 1223, "completion_tokens": 4, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	929bb818-9a7b-4113-b8aa-fcc3f380a6cf	success	{}
chatcmpl-46968241-f394-4108-a5e7-fb381ee31174	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	4645	4096	549	2025-10-06 21:54:40.323	2025-10-06 21:54:58.13	2025-10-06 21:54:49.51	llama3.2:latest	7f6e579f60c2b777101210dad6171eb598f86e47feed3b2855c242bfd4018d32	ollama/llama3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 4645, "prompt_tokens": 4096, "completion_tokens": 549, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "llama3.2:latest", "model_map_value": {"key": "ollama/llama3.2:latest", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	7c1cd899-522a-4f90-91a3-6ae05fc105d3	success	{}
chatcmpl-7c93c5b4-a0dd-43ed-ba3f-678b300d6aa1	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	2353	1962	391	2025-10-06 21:54:58.226	2025-10-06 21:55:12.637	2025-10-06 21:55:06.055	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 2353, "prompt_tokens": 1962, "completion_tokens": 391, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	595d16f9-6f95-43c2-bdb9-51ffc3421338	success	{}
chatcmpl-72ea756e-f283-48a7-aea5-cb4ce6a70033	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	2275	1880	395	2025-10-06 21:54:58.23	2025-10-06 21:55:21.97	2025-10-06 21:55:13.95	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 2275, "prompt_tokens": 1880, "completion_tokens": 395, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	45347d59-a4bc-4b05-90cd-2e030ac313a6	success	{}
chatcmpl-ca5edaee-a996-44d9-a82a-41981c943595	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1563	1552	11	2025-10-06 21:55:11.195	2025-10-06 21:55:23.205	2025-10-06 21:55:23.046	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1563, "prompt_tokens": 1552, "completion_tokens": 11, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	a2b8b5e5-ce20-410e-88ef-c05b5491ae81	success	{}
chatcmpl-671c98d7-22d6-4279-a71b-a40551301df2	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1987	1662	325	2025-10-06 21:55:11.192	2025-10-06 21:55:29.557	2025-10-06 21:55:24.373	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1987, "prompt_tokens": 1662, "completion_tokens": 325, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	a48c4c03-566f-429b-a4e7-7da536d84c80	success	{}
chatcmpl-10215fbb-daaf-4250-a6ee-a45a1e63021a	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	650	626	24	2025-10-06 21:55:12.678	2025-10-06 21:55:30.246	2025-10-06 21:55:29.932	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 650, "prompt_tokens": 626, "completion_tokens": 24, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	2f42f9ed-9faa-4855-901d-f121d2755c5c	success	{}
chatcmpl-63c5cabe-9434-40ba-a0d9-f4f73de27981	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	540	531	9	2025-10-06 21:55:21.997	2025-10-06 21:55:30.389	2025-10-06 21:55:30.279	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 540, "prompt_tokens": 531, "completion_tokens": 9, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	99e0027d-03f9-4832-adf9-cc33d2d897be	success	{}
chatcmpl-7c651db1-58ba-4290-a7ea-e31d8fe14322	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1952	1948	4	2025-10-06 21:55:29.641	2025-10-06 21:55:31.879	2025-10-06 21:55:31.826	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1952, "prompt_tokens": 1948, "completion_tokens": 4, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	9eb2f0d1-f014-4307-a360-b85828f18c16	success	{}
chatcmpl-330c1646-dc77-48e6-96e4-aa8af3308b7b	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	2037	1828	209	2025-10-06 21:55:30.393	2025-10-06 21:55:36.531	2025-10-06 21:55:33.175	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 2037, "prompt_tokens": 1828, "completion_tokens": 209, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	966215ec-a35e-4eb6-8ff7-4bba59e66c46	success	{}
chatcmpl-4b810467-f2a5-4b30-96b1-3b09a9f4396e	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1770	1617	153	2025-10-06 21:55:30.471	2025-10-06 21:55:39.062	2025-10-06 21:55:36.653	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1770, "prompt_tokens": 1617, "completion_tokens": 153, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	5eeee16e-4d1c-4d8a-b127-1bb0cc3814be	success	{}
chatcmpl-eedee21d-a1ba-4200-81a4-1e5945e7f583	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	5200	4096	1104	2025-10-06 21:55:31.918	2025-10-06 21:56:05.454	2025-10-06 21:55:46.597	llama3.2:latest	7f6e579f60c2b777101210dad6171eb598f86e47feed3b2855c242bfd4018d32	ollama/llama3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 5200, "prompt_tokens": 4096, "completion_tokens": 1104, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "llama3.2:latest", "model_map_value": {"key": "ollama/llama3.2:latest", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	9b2d15cb-e3d0-431f-9760-2c803dc33ae1	success	{}
chatcmpl-165653c4-78da-474d-adc1-3695d0d501e1	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	4023	3368	655	2025-10-06 21:56:05.584	2025-10-06 21:56:29.721	2025-10-06 21:56:14.898	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 4023, "prompt_tokens": 3368, "completion_tokens": 655, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	0d1f1b0f-571e-4773-8cc1-ea401dc5d750	success	{}
chatcmpl-9939a413-3455-41be-8158-e41a8c486ca0	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	3941	3286	655	2025-10-06 21:56:05.589	2025-10-06 21:56:45.512	2025-10-06 21:56:32.467	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 3941, "prompt_tokens": 3286, "completion_tokens": 655, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	ae4a13c8-c849-4d4e-aab2-3892c78eece7	success	{}
chatcmpl-081f6d85-b972-4745-8004-bdf9e249cf0f	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	658	638	20	2025-10-06 21:56:29.759	2025-10-06 21:56:46.15	2025-10-06 21:56:45.884	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 658, "prompt_tokens": 638, "completion_tokens": 20, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	e7d3586c-1402-41b5-9864-e1094ded67c4	success	{}
chatcmpl-eae78bf6-461b-4572-8ca0-fca763181d58	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	540	531	9	2025-10-06 21:56:45.546	2025-10-06 21:56:46.292	2025-10-06 21:56:46.183	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 540, "prompt_tokens": 531, "completion_tokens": 9, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	6e653b1e-efaa-48c3-a92d-1b16324367bc	success	{}
chatcmpl-c9c01dc4-ddb8-4966-a170-d68ae0705b75	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1894	1719	175	2025-10-06 21:56:46.265	2025-10-06 21:56:50.301	2025-10-06 21:56:47.504	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1894, "prompt_tokens": 1719, "completion_tokens": 175, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	17e3977e-5b70-4857-ad84-c41d9f76cf38	success	{}
chatcmpl-b1782340-2833-4173-a038-c0da8eeb1ce0	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1866	1667	199	2025-10-06 21:56:46.354	2025-10-06 21:56:53.595	2025-10-06 21:56:50.46	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1866, "prompt_tokens": 1667, "completion_tokens": 199, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	8f71dd2d-90df-4800-ae32-025adf64d6cc	success	{}
chatcmpl-55d0614e-eaf6-4e1a-ac9f-70966a678709	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	3070	3051	19	2025-10-06 22:20:15.92	2025-10-06 22:20:25.927	2025-10-06 22:20:25.573	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 3070, "prompt_tokens": 3051, "completion_tokens": 19, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	1f5b3654-1ac0-429d-bb45-79d3d6dcb3ca	success	{}
chatcmpl-ee9dc1fa-e13a-46e8-864c-3d01e0f3d602	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	16916	16907	9	2025-10-06 22:22:31.128	2025-10-06 22:22:47.936	2025-10-06 22:22:47.418	llama3.2:latest	7f6e579f60c2b777101210dad6171eb598f86e47feed3b2855c242bfd4018d32	ollama/llama3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 16916, "prompt_tokens": 16907, "completion_tokens": 9, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "llama3.2:latest", "model_map_value": {"key": "ollama/llama3.2:latest", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	50321150-ee2c-4190-8cef-8d503ef81986	success	{}
chatcmpl-a523b96b-378c-44de-8159-b9b5ff92b479	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	3604	2958	646	2025-10-06 22:20:15.921	2025-10-06 22:20:42.158	2025-10-06 22:20:28.287	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 3604, "prompt_tokens": 2958, "completion_tokens": 646, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	14836c05-73b0-482d-855c-97f461685b8d	success	{}
chatcmpl-98975faa-cd8e-4203-8b8a-e2cb29c0dd32	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	4619	4096	523	2025-10-06 22:20:26.004	2025-10-06 22:20:57.944	2025-10-06 22:20:49.872	llama3.2:latest	af69ac2d-5c66-4bea-8969-635937134486	ollama/llama3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 4619, "prompt_tokens": 4096, "completion_tokens": 523, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "llama3.2:latest", "model_map_value": {"key": "ollama/llama3.2:latest", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	fec671d3-3e98-427d-8d6b-218a8a471a8d	success	{}
chatcmpl-ea9dcaa6-e181-4f21-9bbc-802362febf32	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	4687	4037	650	2025-10-06 22:20:58.025	2025-10-06 22:21:23.835	2025-10-06 22:21:08.795	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 4687, "prompt_tokens": 4037, "completion_tokens": 650, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	6758aa45-fa4b-4e90-ac28-696846e4b3e0	success	{}
chatcmpl-7e00e6e2-803b-48ad-bb83-4676cf629ea0	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	4605	3955	650	2025-10-06 22:20:58.032	2025-10-06 22:21:41.54	2025-10-06 22:21:27.446	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 4605, "prompt_tokens": 3955, "completion_tokens": 650, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	bd98b372-254b-42b5-a39c-5f517001f77d	success	{}
chatcmpl-97d9201f-c56a-48c1-8a3f-434bf4521933	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	4269	3621	648	2025-10-06 22:21:08.498	2025-10-06 22:21:57.881	2025-10-06 22:21:44.719	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 4269, "prompt_tokens": 3621, "completion_tokens": 648, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	25215908-9b62-4dc1-80ce-4e04181ed23c	success	{}
chatcmpl-908b3f2d-9819-40f7-a617-d37e0cde8e99	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	3929	3295	634	2025-10-06 22:21:08.5	2025-10-06 22:22:14.723	2025-10-06 22:22:00.65	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 3929, "prompt_tokens": 3295, "completion_tokens": 634, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	aeaa03b4-424b-4572-b95c-d6316f7a39e6	success	{}
chatcmpl-8d26f36c-893a-486a-9764-e047d1c95661	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	658	638	20	2025-10-06 22:21:23.874	2025-10-06 22:22:15.355	2025-10-06 22:22:15.096	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 658, "prompt_tokens": 638, "completion_tokens": 20, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	4cdef5d2-2119-4120-b3a6-61be0ac3bc7c	success	{}
chatcmpl-ebeb9700-ec5d-4b02-8a39-0a014a5f3c87	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	540	531	9	2025-10-06 22:21:41.576	2025-10-06 22:22:15.504	2025-10-06 22:22:15.393	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 540, "prompt_tokens": 531, "completion_tokens": 9, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	b1b887b4-5431-4b46-9aa5-bbd4bdcc5b4a	success	{}
chatcmpl-34ed6da5-69f8-4b5b-a431-76ee57ae9ef7	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	4080	3446	634	2025-10-06 22:22:14.846	2025-10-06 22:22:31.082	2025-10-06 22:22:18.491	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 4080, "prompt_tokens": 3446, "completion_tokens": 634, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	f4aff537-ff05-40f4-97c3-cd0180d6dd53	success	{}
chatcmpl-e8f6ec21-5471-4c25-884e-31bb30c181d5	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1922	1716	206	2025-10-06 22:22:15.566	2025-10-06 22:22:38.432	2025-10-06 22:22:35.185	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1922, "prompt_tokens": 1716, "completion_tokens": 206, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	49aa2e71-eeda-43fd-9c2a-b0784d00d21b	success	{}
96038561-296e-4894-a9f3-1c912a98e45e			0	0	0	0	2025-10-06 22:23:06.175	2025-10-06 22:23:06.175	2025-10-06 22:23:06.174	ollama/llama3.2:latest	7f6e579f60c2b777101210dad6171eb598f86e47feed3b2855c242bfd4018d32	ollama/llama3.2:latest			default_user_id	{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/proxy_server.py\\", line 3648, in chat_completion\\n    return await base_llm_response_processor.base_process_llm_request(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<16 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/common_request_processing.py\\", line 399, in base_process_llm_request\\n    responses = await llm_responses\\n                ^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 997, in acompletion\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 973, in acompletion\\n    response = await self.async_function_with_fallbacks(**kwargs)\\n               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 3574, in async_function_with_fallbacks\\n    raise original_exception\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 3388, in async_function_with_fallbacks\\n    response = await self.async_function_with_retries(*args, **kwargs)\\n               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 3766, in async_function_with_retries\\n    raise original_exception\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 3657, in async_function_with_retries\\n    response = await self.make_call(original_function, *args, **kwargs)\\n               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 3775, in make_call\\n    response = await response\\n               ^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 1136, in _acompletion\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 1095, in _acompletion\\n    response = await _response\\n               ^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/utils.py\\", line 1495, in wrapper_async\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/utils.py\\", line 1356, in wrapper_async\\n    result = await original_function(*args, **kwargs)\\n             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/main.py\\", line 544, in acompletion\\n    raise exception_type(\\n          ~~~~~~~~~~~~~~^\\n        model=model,\\n        ^^^^^^^^^^^^\\n    ...<3 lines>...\\n        extra_kwargs=kwargs,\\n        ^^^^^^^^^^^^^^^^^^^^\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/exception_mapping_utils.py\\", line 2271, in exception_type\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/exception_mapping_utils.py\\", line 2240, in exception_type\\n    raise APIConnectionError(\\n    ...<4 lines>...\\n    )\\n", "error_code": "500", "error_class": "APIConnectionError", "llm_provider": "ollama", "error_message": "litellm.APIConnectionError: OllamaException - Server disconnected. Received Model Group=ollama/llama3.2:latest\\nAvailable Model Group Fallbacks=None LiteLLM Retried: 1 times, LiteLLM Max Retries: 2"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]				{}	{}	7438aedf-7e7d-4027-b91c-f25e1dd66d3b	failure	{}
f41f11de-c2f6-4b2f-8647-e8beed10383d			0	0	0	0	2025-10-06 22:23:07.219	2025-10-06 22:23:07.219	2025-10-06 22:23:07.219	ollama/llama3.2:latest	af69ac2d-5c66-4bea-8969-635937134486	ollama/llama3.2:latest			default_user_id	{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/proxy_server.py\\", line 3648, in chat_completion\\n    return await base_llm_response_processor.base_process_llm_request(\\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n    ...<16 lines>...\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/common_request_processing.py\\", line 399, in base_process_llm_request\\n    responses = await llm_responses\\n                ^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 997, in acompletion\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 973, in acompletion\\n    response = await self.async_function_with_fallbacks(**kwargs)\\n               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 3574, in async_function_with_fallbacks\\n    raise original_exception\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 3388, in async_function_with_fallbacks\\n    response = await self.async_function_with_retries(*args, **kwargs)\\n               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 3766, in async_function_with_retries\\n    raise original_exception\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 3657, in async_function_with_retries\\n    response = await self.make_call(original_function, *args, **kwargs)\\n               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 3775, in make_call\\n    response = await response\\n               ^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 1136, in _acompletion\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/router.py\\", line 1095, in _acompletion\\n    response = await _response\\n               ^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/utils.py\\", line 1495, in wrapper_async\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/utils.py\\", line 1356, in wrapper_async\\n    result = await original_function(*args, **kwargs)\\n             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/main.py\\", line 544, in acompletion\\n    raise exception_type(\\n          ~~~~~~~~~~~~~~^\\n        model=model,\\n        ^^^^^^^^^^^^\\n    ...<3 lines>...\\n        extra_kwargs=kwargs,\\n        ^^^^^^^^^^^^^^^^^^^^\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/exception_mapping_utils.py\\", line 2271, in exception_type\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/exception_mapping_utils.py\\", line 2240, in exception_type\\n    raise APIConnectionError(\\n    ...<4 lines>...\\n    )\\n", "error_code": "500", "error_class": "APIConnectionError", "llm_provider": "ollama", "error_message": "litellm.APIConnectionError: OllamaException - Cannot connect to host host.docker.internal:11434 ssl:default [Connect call failed ('192.168.65.254', 11434)]. Received Model Group=ollama/llama3.2:latest\\nAvailable Model Group Fallbacks=None LiteLLM Retried: 1 times, LiteLLM Max Retries: 2"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]				{}	{}	aa9580f7-8064-43d5-b987-d3ca4539bd3e	failure	{}
3c43ae8f-64c6-4728-97dd-b3b5187361f9			0	0	0	0	2025-10-06 22:22:56.663	2025-10-06 22:22:56.663	2025-10-06 22:22:56.662	ollama/llama3.2:latest	af69ac2d-5c66-4bea-8969-635937134486	ollama/llama3.2:latest			default_user_id	{"status": "failure", "batch_models": null, "usage_object": null, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "error_information": {"traceback": "  File \\"/usr/lib/python3.13/site-packages/litellm/proxy/proxy_server.py\\", line 3122, in async_data_generator\\n    async for chunk in proxy_logging_obj.async_post_call_streaming_iterator_hook(\\n    ...<18 lines>...\\n            yield f\\"data: {str(e)}\\\\n\\\\n\\"\\n  File \\"/usr/lib/python3.13/site-packages/litellm/integrations/custom_logger.py\\", line 291, in async_post_call_streaming_iterator_hook\\n    async for item in response:\\n        yield item\\n  File \\"/usr/lib/python3.13/site-packages/litellm/integrations/custom_logger.py\\", line 291, in async_post_call_streaming_iterator_hook\\n    async for item in response:\\n        yield item\\n  File \\"/usr/lib/python3.13/site-packages/litellm/integrations/custom_logger.py\\", line 291, in async_post_call_streaming_iterator_hook\\n    async for item in response:\\n        yield item\\n  [Previous line repeated 4 more times]\\n  File \\"/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/streaming_handler.py\\", line 1817, in __anext__\\n    raise exception_type(\\n          ~~~~~~~~~~~~~~^\\n        model=self.model,\\n        ^^^^^^^^^^^^^^^^^\\n    ...<3 lines>...\\n        extra_kwargs={},\\n        ^^^^^^^^^^^^^^^^\\n    )\\n    ^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/exception_mapping_utils.py\\", line 2271, in exception_type\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/exception_mapping_utils.py\\", line 2247, in exception_type\\n    raise APIConnectionError(\\n    ...<8 lines>...\\n    )\\n", "error_code": "500", "error_class": "APIConnectionError", "llm_provider": "ollama", "error_message": "litellm.APIConnectionError: Ollama Error - {'error': 'model runner has unexpectedly stopped, this may be due to resource limitations or an internal error, check ollama server logs for details'}\\nTraceback (most recent call last):\\n  File \\"/usr/lib/python3.13/site-packages/litellm/litellm_core_utils/streaming_handler.py\\", line 1653, in __anext__\\n    async for chunk in self.completion_stream:\\n    ...<51 lines>...\\n        return processed_chunk\\n  File \\"/usr/lib/python3.13/site-packages/litellm/llms/base_llm/base_model_iterator.py\\", line 128, in __anext__\\n    chunk = self._handle_string_chunk(str_line=str_line)\\n  File \\"/usr/lib/python3.13/site-packages/litellm/llms/ollama/completion/transformation.py\\", line 422, in _handle_string_chunk\\n    return self.chunk_parser(json.loads(str_line))\\n           ~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^\\n  File \\"/usr/lib/python3.13/site-packages/litellm/llms/ollama/completion/transformation.py\\", line 463, in chunk_parser\\n    raise e\\n  File \\"/usr/lib/python3.13/site-packages/litellm/llms/ollama/completion/transformation.py\\", line 427, in chunk_parser\\n    raise Exception(f\\"Ollama Error - {chunk}\\")\\nException: Ollama Error - {'error': 'model runner has unexpectedly stopped, this may be due to resource limitations or an internal error, check ollama server logs for details'}\\n"}, "applied_guardrails": null, "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": null, "mcp_tool_call_metadata": null, "additional_usage_values": {}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	[]				{}	{}	06747c29-f346-40d4-b4da-7456800c5a53	failure	{}
chatcmpl-f344f2aa-6c5d-4ecc-b205-5e4924e7595e	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	5320	4096	1224	2025-10-06 22:23:08.745	2025-10-06 22:23:38.511	2025-10-06 22:23:21.046	llama3.2:latest	7f6e579f60c2b777101210dad6171eb598f86e47feed3b2855c242bfd4018d32	ollama/llama3.2:latest	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 5320, "prompt_tokens": 4096, "completion_tokens": 1224, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "llama3.2:latest", "model_map_value": {"key": "ollama/llama3.2:latest", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	4bf595e8-903d-4a98-994a-30431d28a2f2	success	{}
chatcmpl-8b2eb87a-3225-4679-88ea-860d888b4272	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	4747	4096	651	2025-10-06 22:23:38.618	2025-10-06 22:24:02.061	2025-10-06 22:23:49.565	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 4747, "prompt_tokens": 4096, "completion_tokens": 651, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	1fa19901-db2a-4149-94b1-7b8e9a4543af	success	{}
chatcmpl-888d75d1-fc67-4d57-91a8-c5fa881720cf	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	4747	4096	651	2025-10-06 22:23:38.621	2025-10-06 22:24:20.774	2025-10-06 22:24:05.8	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 4747, "prompt_tokens": 4096, "completion_tokens": 651, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	52037669-af95-4686-afa6-0c30481ef1be	success	{}
chatcmpl-f19e4f16-0ec5-474c-948f-7ff572af1660	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	658	638	20	2025-10-06 22:24:02.101	2025-10-06 22:24:21.377	2025-10-06 22:24:21.146	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 658, "prompt_tokens": 638, "completion_tokens": 20, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	d21345ec-ce5a-453d-a3d1-286985af5b31	success	{}
chatcmpl-431e9bb2-50ba-4a29-b6f4-5bb3c74b1732	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	540	531	9	2025-10-06 22:24:20.813	2025-10-06 22:24:21.505	2025-10-06 22:24:21.408	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 540, "prompt_tokens": 531, "completion_tokens": 9, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	eb8cec4d-db64-4ab7-83e3-37404be10e20	success	{}
chatcmpl-074313c8-3e6b-4f57-8e5a-dab091c9957d	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1933	1721	212	2025-10-06 22:24:21.478	2025-10-06 22:24:25.788	2025-10-06 22:24:22.714	openchat:7b-v3.5-1210	076472785cc07001621d998bd79c43e1a65198d405f9b2b7e7c49719658ab664	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1933, "prompt_tokens": 1721, "completion_tokens": 212, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	48c9cd51-1365-48d4-8c61-196f9ff07193	success	{}
chatcmpl-f09cd5f6-362a-4716-bdf4-d9e382b7e534	acompletion	sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62	0	1778	1617	161	2025-10-06 22:24:21.565	2025-10-06 22:24:28.189	2025-10-06 22:24:25.91	openchat:7b-v3.5-1210	77457a69-b559-482e-a47e-e6d6657c383a	ollama/openchat:7b-v3.5-1210	ollama	http://host.docker.internal:11434/api/generate	default_user_id	{"batch_models": null, "usage_object": {"total_tokens": 1778, "prompt_tokens": 1617, "completion_tokens": 161, "prompt_tokens_details": null, "completion_tokens_details": {"audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key": "sk_622f859d0f312e36c1598da4895eb18495392024969198ea44a2c6b3b900da62", "applied_guardrails": [], "user_api_key_alias": null, "user_api_key_org_id": null, "requester_ip_address": "", "user_api_key_team_id": null, "user_api_key_user_id": "default_user_id", "guardrail_information": null, "model_map_information": {"model_map_key": "openchat:7b-v3.5-1210", "model_map_value": {"key": "ollama/openchat:7b-v3.5-1210", "rpm": null, "tpm": null, "mode": null, "max_tokens": null, "supports_vision": null, "litellm_provider": "ollama", "max_input_tokens": null, "max_output_tokens": null, "output_vector_size": null, "supports_pdf_input": null, "supports_reasoning": null, "supports_web_search": null, "input_cost_per_query": null, "input_cost_per_token": 0, "supports_audio_input": null, "supports_tool_choice": null, "supports_url_context": null, "input_cost_per_second": null, "output_cost_per_image": null, "output_cost_per_token": 0, "supports_audio_output": null, "supports_computer_use": null, "output_cost_per_second": null, "supported_openai_params": ["max_tokens", "stream", "top_p", "temperature", "seed", "frequency_penalty", "stop", "response_format", "max_completion_tokens"], "supports_prompt_caching": null, "input_cost_per_character": null, "supports_response_schema": null, "supports_system_messages": null, "output_cost_per_character": null, "supports_function_calling": null, "supports_native_streaming": null, "input_cost_per_audio_token": null, "supports_assistant_prefill": null, "cache_read_input_token_cost": null, "output_cost_per_audio_token": null, "input_cost_per_token_batches": null, "output_cost_per_token_batches": null, "search_context_cost_per_query": null, "supports_embedding_image_input": null, "cache_creation_input_token_cost": null, "output_cost_per_reasoning_token": null, "input_cost_per_token_above_128k_tokens": null, "input_cost_per_token_above_200k_tokens": null, "output_cost_per_token_above_128k_tokens": null, "output_cost_per_token_above_200k_tokens": null, "output_cost_per_character_above_128k_tokens": null}}, "mcp_tool_call_metadata": null, "additional_usage_values": {"prompt_tokens_details": null, "completion_tokens_details": {"text_tokens": null, "audio_tokens": null, "reasoning_tokens": 0, "accepted_prediction_tokens": null, "rejected_prediction_tokens": null}}, "user_api_key_team_alias": null, "vector_store_request_metadata": null}	False	Cache OFF	["User-Agent: AsyncOpenAI", "User-Agent: AsyncOpenAI/Python 1.99.2"]				{}	{}	3582b72d-5cf7-497e-9997-fb9c1c298928	success	{}
\.


--
-- Data for Name: LiteLLM_TeamMembership; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_TeamMembership" (user_id, team_id, spend, budget_id) FROM stdin;
\.


--
-- Data for Name: LiteLLM_TeamTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_TeamTable" (team_id, team_alias, organization_id, object_permission_id, admins, members, members_with_roles, metadata, max_budget, spend, models, max_parallel_requests, tpm_limit, rpm_limit, budget_duration, budget_reset_at, blocked, created_at, updated_at, model_spend, model_max_budget, team_member_permissions, model_id) FROM stdin;
\.


--
-- Data for Name: LiteLLM_UserNotifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_UserNotifications" (request_id, user_id, models, justification, status) FROM stdin;
\.


--
-- Data for Name: LiteLLM_UserTable; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_UserTable" (user_id, user_alias, team_id, sso_user_id, organization_id, object_permission_id, password, teams, user_role, max_budget, spend, user_email, models, metadata, max_parallel_requests, tpm_limit, rpm_limit, budget_duration, budget_reset_at, allowed_cache_controls, model_spend, model_max_budget, created_at, updated_at) FROM stdin;
default_user_id	\N	\N	\N	\N	\N	\N	{}	proxy_admin	\N	0	jerryagenyi@gmail.com	\N	{}	\N	\N	\N	\N	\N	{}	{}	{}	2025-06-21 12:40:13.106	2025-10-06 22:24:31.332
\.


--
-- Data for Name: LiteLLM_VerificationToken; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."LiteLLM_VerificationToken" (token, key_name, key_alias, soft_budget_cooldown, spend, expires, models, aliases, config, user_id, team_id, permissions, max_parallel_requests, metadata, blocked, tpm_limit, rpm_limit, max_budget, budget_duration, budget_reset_at, allowed_cache_controls, allowed_routes, model_spend, model_max_budget, budget_id, organization_id, object_permission_id, created_at, created_by, updated_at, updated_by) FROM stdin;
797d4088f7bb4c6362974405654a7c9b49c1fb461facec130827e238e17f7dc6	sk-...k3Jw	\N	f	0	2025-06-22 12:40:13.113	{}	{}	{}	default_user_id	litellm-dashboard	{}	\N	{}	\N	\N	\N	10	\N	\N	{}	{}	{}	{}	\N	\N	\N	2025-06-21 12:40:13.117	\N	2025-06-21 12:40:13.117	\N
37a29590f21669e38e1fe4af8a9718f7a0cc2c180623ec1a3a85021604b2ffee	sk-...kj5g	\N	f	0	2025-06-22 16:46:51.753	{}	{}	{}	default_user_id	litellm-dashboard	{}	\N	{}	\N	\N	\N	10	\N	\N	{}	{}	{}	{}	\N	\N	\N	2025-06-21 16:46:51.757	\N	2025-06-23 06:55:47.998	\N
d26ebd0e5da19a7853b062cf489c2f4bf58e97a3f3a600f2a3ac572450a65c7a	sk-...Z2sQ	\N	f	0	2025-06-24 20:00:31.551	{}	{}	{}	default_user_id	litellm-dashboard	{}	\N	{}	\N	\N	\N	10	\N	\N	{}	{}	{}	{}	\N	\N	\N	2025-06-23 20:00:31.556	\N	2025-06-23 20:00:31.556	\N
8569b3bf513cd8fdf806b2d5dd8e6dcb813fa9a33c87c37583a75770105fab3f	sk-...cvdA	\N	f	0	2025-07-06 17:04:07.174	{}	{}	{}	default_user_id	litellm-dashboard	{}	\N	{}	\N	\N	\N	10	\N	\N	{}	{}	{}	{}	\N	\N	\N	2025-07-05 17:04:07.183	\N	2025-07-05 17:06:29.234	\N
c2203891d447ff73082204c3643a621bc45dfe783a5a6ac74c05a045daf7fdb3	sk-...6hCQ	\N	f	0	2025-08-04 17:47:39.195	{ollama/llama2}	{}	{}	\N	\N	{}	\N	{}	\N	\N	\N	\N	\N	\N	{}	{}	{}	{}	\N	\N	\N	2025-07-05 17:47:39.198	default_user_id	2025-07-05 17:47:39.198	default_user_id
43ab40516dc7b7974fdb7396dbfe08bdd56141d7bc98ba94b37898d66f590447	sk-...zAew	\N	f	0	2025-07-29 14:40:20.686	{}	{}	{}	default_user_id	litellm-dashboard	{}	\N	{}	\N	\N	\N	10	\N	\N	{}	{}	{}	{}	\N	\N	\N	2025-07-28 14:40:20.69	\N	2025-07-28 14:40:20.69	\N
4c3ea9d6ac7ceadf186d140d544d887ac46a0c61d45ad40008d383c85b44581b	sk-...KxiQ	\N	f	0	2025-09-29 06:01:12.161	{}	{}	{}	default_user_id	litellm-dashboard	{}	\N	{}	\N	\N	\N	10	\N	\N	{}	{}	{}	{}	\N	\N	\N	2025-09-28 06:01:12.166	\N	2025-09-28 06:01:12.166	\N
f25324cf7c4aa16eaf0c5f84339706dc95229d3676515b1bf87af4e1be60119a	sk-...B5Cg	\N	f	0	2025-09-29 11:51:29.682	{}	{}	{}	default_user_id	litellm-dashboard	{}	\N	{}	\N	\N	\N	10	\N	\N	{}	{}	{}	{}	\N	\N	\N	2025-09-28 11:51:29.686	\N	2025-09-28 11:51:29.686	\N
1a90bb98c4037a08731cd375cbe5d16667be87b5ff32b077f2e30a76bc580e3e	sk-...GKnQ	\N	f	0	2025-10-07 20:04:09.431	{}	{}	{}	default_user_id	litellm-dashboard	{}	\N	{}	\N	\N	\N	10	\N	\N	{}	{}	{}	{}	\N	\N	\N	2025-10-06 20:04:09.443	\N	2025-10-06 20:04:09.443	\N
b29de98af56819606c36e5993b664d2fa796778017d0041b9690ec25c94d26ff	sk-...sVaQ	\N	f	0	2025-08-04 17:50:46.559	{ollama/llama3.2:latest}	{}	{}	\N	\N	{}	\N	{}	\N	\N	\N	\N	\N	\N	{}	{}	{}	{}	\N	\N	\N	2025-07-05 17:50:46.563	default_user_id	2025-10-06 21:29:14.609	default_user_id
\.


--
-- Name: LiteLLM_ModelTable_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."LiteLLM_ModelTable_id_seq"', 1, false);


--
-- Name: LiteLLM_AuditLog LiteLLM_AuditLog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_AuditLog"
    ADD CONSTRAINT "LiteLLM_AuditLog_pkey" PRIMARY KEY (id);


--
-- Name: LiteLLM_BudgetTable LiteLLM_BudgetTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_BudgetTable"
    ADD CONSTRAINT "LiteLLM_BudgetTable_pkey" PRIMARY KEY (budget_id);


--
-- Name: LiteLLM_Config LiteLLM_Config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_Config"
    ADD CONSTRAINT "LiteLLM_Config_pkey" PRIMARY KEY (param_name);


--
-- Name: LiteLLM_CredentialsTable LiteLLM_CredentialsTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_CredentialsTable"
    ADD CONSTRAINT "LiteLLM_CredentialsTable_pkey" PRIMARY KEY (credential_id);


--
-- Name: LiteLLM_CronJob LiteLLM_CronJob_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_CronJob"
    ADD CONSTRAINT "LiteLLM_CronJob_pkey" PRIMARY KEY (cronjob_id);


--
-- Name: LiteLLM_DailyTagSpend LiteLLM_DailyTagSpend_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_DailyTagSpend"
    ADD CONSTRAINT "LiteLLM_DailyTagSpend_pkey" PRIMARY KEY (id);


--
-- Name: LiteLLM_DailyTeamSpend LiteLLM_DailyTeamSpend_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_DailyTeamSpend"
    ADD CONSTRAINT "LiteLLM_DailyTeamSpend_pkey" PRIMARY KEY (id);


--
-- Name: LiteLLM_DailyUserSpend LiteLLM_DailyUserSpend_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_DailyUserSpend"
    ADD CONSTRAINT "LiteLLM_DailyUserSpend_pkey" PRIMARY KEY (id);


--
-- Name: LiteLLM_EndUserTable LiteLLM_EndUserTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_EndUserTable"
    ADD CONSTRAINT "LiteLLM_EndUserTable_pkey" PRIMARY KEY (user_id);


--
-- Name: LiteLLM_ErrorLogs LiteLLM_ErrorLogs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_ErrorLogs"
    ADD CONSTRAINT "LiteLLM_ErrorLogs_pkey" PRIMARY KEY (request_id);


--
-- Name: LiteLLM_GuardrailsTable LiteLLM_GuardrailsTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_GuardrailsTable"
    ADD CONSTRAINT "LiteLLM_GuardrailsTable_pkey" PRIMARY KEY (guardrail_id);


--
-- Name: LiteLLM_HealthCheckTable LiteLLM_HealthCheckTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_HealthCheckTable"
    ADD CONSTRAINT "LiteLLM_HealthCheckTable_pkey" PRIMARY KEY (health_check_id);


--
-- Name: LiteLLM_InvitationLink LiteLLM_InvitationLink_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_InvitationLink"
    ADD CONSTRAINT "LiteLLM_InvitationLink_pkey" PRIMARY KEY (id);


--
-- Name: LiteLLM_MCPServerTable LiteLLM_MCPServerTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_MCPServerTable"
    ADD CONSTRAINT "LiteLLM_MCPServerTable_pkey" PRIMARY KEY (server_id);


--
-- Name: LiteLLM_ManagedFileTable LiteLLM_ManagedFileTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_ManagedFileTable"
    ADD CONSTRAINT "LiteLLM_ManagedFileTable_pkey" PRIMARY KEY (id);


--
-- Name: LiteLLM_ManagedObjectTable LiteLLM_ManagedObjectTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_ManagedObjectTable"
    ADD CONSTRAINT "LiteLLM_ManagedObjectTable_pkey" PRIMARY KEY (id);


--
-- Name: LiteLLM_ManagedVectorStoresTable LiteLLM_ManagedVectorStoresTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_ManagedVectorStoresTable"
    ADD CONSTRAINT "LiteLLM_ManagedVectorStoresTable_pkey" PRIMARY KEY (vector_store_id);


--
-- Name: LiteLLM_ModelTable LiteLLM_ModelTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_ModelTable"
    ADD CONSTRAINT "LiteLLM_ModelTable_pkey" PRIMARY KEY (id);


--
-- Name: LiteLLM_ObjectPermissionTable LiteLLM_ObjectPermissionTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_ObjectPermissionTable"
    ADD CONSTRAINT "LiteLLM_ObjectPermissionTable_pkey" PRIMARY KEY (object_permission_id);


--
-- Name: LiteLLM_OrganizationMembership LiteLLM_OrganizationMembership_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_OrganizationMembership"
    ADD CONSTRAINT "LiteLLM_OrganizationMembership_pkey" PRIMARY KEY (user_id, organization_id);


--
-- Name: LiteLLM_OrganizationTable LiteLLM_OrganizationTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_OrganizationTable"
    ADD CONSTRAINT "LiteLLM_OrganizationTable_pkey" PRIMARY KEY (organization_id);


--
-- Name: LiteLLM_ProxyModelTable LiteLLM_ProxyModelTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_ProxyModelTable"
    ADD CONSTRAINT "LiteLLM_ProxyModelTable_pkey" PRIMARY KEY (model_id);


--
-- Name: LiteLLM_SpendLogs LiteLLM_SpendLogs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_SpendLogs"
    ADD CONSTRAINT "LiteLLM_SpendLogs_pkey" PRIMARY KEY (request_id);


--
-- Name: LiteLLM_TeamMembership LiteLLM_TeamMembership_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_TeamMembership"
    ADD CONSTRAINT "LiteLLM_TeamMembership_pkey" PRIMARY KEY (user_id, team_id);


--
-- Name: LiteLLM_TeamTable LiteLLM_TeamTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_TeamTable"
    ADD CONSTRAINT "LiteLLM_TeamTable_pkey" PRIMARY KEY (team_id);


--
-- Name: LiteLLM_UserNotifications LiteLLM_UserNotifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_UserNotifications"
    ADD CONSTRAINT "LiteLLM_UserNotifications_pkey" PRIMARY KEY (request_id);


--
-- Name: LiteLLM_UserTable LiteLLM_UserTable_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_UserTable"
    ADD CONSTRAINT "LiteLLM_UserTable_pkey" PRIMARY KEY (user_id);


--
-- Name: LiteLLM_VerificationToken LiteLLM_VerificationToken_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_VerificationToken"
    ADD CONSTRAINT "LiteLLM_VerificationToken_pkey" PRIMARY KEY (token);


--
-- Name: LiteLLM_CredentialsTable_credential_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_CredentialsTable_credential_name_key" ON public."LiteLLM_CredentialsTable" USING btree (credential_name);


--
-- Name: LiteLLM_DailyTagSpend_api_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyTagSpend_api_key_idx" ON public."LiteLLM_DailyTagSpend" USING btree (api_key);


--
-- Name: LiteLLM_DailyTagSpend_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyTagSpend_date_idx" ON public."LiteLLM_DailyTagSpend" USING btree (date);


--
-- Name: LiteLLM_DailyTagSpend_model_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyTagSpend_model_idx" ON public."LiteLLM_DailyTagSpend" USING btree (model);


--
-- Name: LiteLLM_DailyTagSpend_tag_date_api_key_model_custom_llm_pro_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_DailyTagSpend_tag_date_api_key_model_custom_llm_pro_key" ON public."LiteLLM_DailyTagSpend" USING btree (tag, date, api_key, model, custom_llm_provider);


--
-- Name: LiteLLM_DailyTagSpend_tag_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyTagSpend_tag_idx" ON public."LiteLLM_DailyTagSpend" USING btree (tag);


--
-- Name: LiteLLM_DailyTeamSpend_api_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyTeamSpend_api_key_idx" ON public."LiteLLM_DailyTeamSpend" USING btree (api_key);


--
-- Name: LiteLLM_DailyTeamSpend_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyTeamSpend_date_idx" ON public."LiteLLM_DailyTeamSpend" USING btree (date);


--
-- Name: LiteLLM_DailyTeamSpend_model_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyTeamSpend_model_idx" ON public."LiteLLM_DailyTeamSpend" USING btree (model);


--
-- Name: LiteLLM_DailyTeamSpend_team_id_date_api_key_model_custom_ll_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_DailyTeamSpend_team_id_date_api_key_model_custom_ll_key" ON public."LiteLLM_DailyTeamSpend" USING btree (team_id, date, api_key, model, custom_llm_provider);


--
-- Name: LiteLLM_DailyTeamSpend_team_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyTeamSpend_team_id_idx" ON public."LiteLLM_DailyTeamSpend" USING btree (team_id);


--
-- Name: LiteLLM_DailyUserSpend_api_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyUserSpend_api_key_idx" ON public."LiteLLM_DailyUserSpend" USING btree (api_key);


--
-- Name: LiteLLM_DailyUserSpend_date_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyUserSpend_date_idx" ON public."LiteLLM_DailyUserSpend" USING btree (date);


--
-- Name: LiteLLM_DailyUserSpend_model_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyUserSpend_model_idx" ON public."LiteLLM_DailyUserSpend" USING btree (model);


--
-- Name: LiteLLM_DailyUserSpend_user_id_date_api_key_model_custom_ll_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_DailyUserSpend_user_id_date_api_key_model_custom_ll_key" ON public."LiteLLM_DailyUserSpend" USING btree (user_id, date, api_key, model, custom_llm_provider);


--
-- Name: LiteLLM_DailyUserSpend_user_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_DailyUserSpend_user_id_idx" ON public."LiteLLM_DailyUserSpend" USING btree (user_id);


--
-- Name: LiteLLM_GuardrailsTable_guardrail_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_GuardrailsTable_guardrail_name_key" ON public."LiteLLM_GuardrailsTable" USING btree (guardrail_name);


--
-- Name: LiteLLM_HealthCheckTable_checked_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_HealthCheckTable_checked_at_idx" ON public."LiteLLM_HealthCheckTable" USING btree (checked_at);


--
-- Name: LiteLLM_HealthCheckTable_model_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_HealthCheckTable_model_name_idx" ON public."LiteLLM_HealthCheckTable" USING btree (model_name);


--
-- Name: LiteLLM_HealthCheckTable_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_HealthCheckTable_status_idx" ON public."LiteLLM_HealthCheckTable" USING btree (status);


--
-- Name: LiteLLM_ManagedFileTable_unified_file_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_ManagedFileTable_unified_file_id_idx" ON public."LiteLLM_ManagedFileTable" USING btree (unified_file_id);


--
-- Name: LiteLLM_ManagedFileTable_unified_file_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_ManagedFileTable_unified_file_id_key" ON public."LiteLLM_ManagedFileTable" USING btree (unified_file_id);


--
-- Name: LiteLLM_ManagedObjectTable_model_object_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_ManagedObjectTable_model_object_id_idx" ON public."LiteLLM_ManagedObjectTable" USING btree (model_object_id);


--
-- Name: LiteLLM_ManagedObjectTable_model_object_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_ManagedObjectTable_model_object_id_key" ON public."LiteLLM_ManagedObjectTable" USING btree (model_object_id);


--
-- Name: LiteLLM_ManagedObjectTable_unified_object_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_ManagedObjectTable_unified_object_id_idx" ON public."LiteLLM_ManagedObjectTable" USING btree (unified_object_id);


--
-- Name: LiteLLM_ManagedObjectTable_unified_object_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_ManagedObjectTable_unified_object_id_key" ON public."LiteLLM_ManagedObjectTable" USING btree (unified_object_id);


--
-- Name: LiteLLM_OrganizationMembership_user_id_organization_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_OrganizationMembership_user_id_organization_id_key" ON public."LiteLLM_OrganizationMembership" USING btree (user_id, organization_id);


--
-- Name: LiteLLM_SpendLogs_end_user_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_SpendLogs_end_user_idx" ON public."LiteLLM_SpendLogs" USING btree (end_user);


--
-- Name: LiteLLM_SpendLogs_session_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_SpendLogs_session_id_idx" ON public."LiteLLM_SpendLogs" USING btree (session_id);


--
-- Name: LiteLLM_SpendLogs_startTime_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "LiteLLM_SpendLogs_startTime_idx" ON public."LiteLLM_SpendLogs" USING btree ("startTime");


--
-- Name: LiteLLM_TeamTable_model_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_TeamTable_model_id_key" ON public."LiteLLM_TeamTable" USING btree (model_id);


--
-- Name: LiteLLM_UserTable_sso_user_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "LiteLLM_UserTable_sso_user_id_key" ON public."LiteLLM_UserTable" USING btree (sso_user_id);


--
-- Name: LiteLLM_EndUserTable LiteLLM_EndUserTable_budget_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_EndUserTable"
    ADD CONSTRAINT "LiteLLM_EndUserTable_budget_id_fkey" FOREIGN KEY (budget_id) REFERENCES public."LiteLLM_BudgetTable"(budget_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_InvitationLink LiteLLM_InvitationLink_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_InvitationLink"
    ADD CONSTRAINT "LiteLLM_InvitationLink_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public."LiteLLM_UserTable"(user_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: LiteLLM_InvitationLink LiteLLM_InvitationLink_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_InvitationLink"
    ADD CONSTRAINT "LiteLLM_InvitationLink_updated_by_fkey" FOREIGN KEY (updated_by) REFERENCES public."LiteLLM_UserTable"(user_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: LiteLLM_InvitationLink LiteLLM_InvitationLink_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_InvitationLink"
    ADD CONSTRAINT "LiteLLM_InvitationLink_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public."LiteLLM_UserTable"(user_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: LiteLLM_OrganizationMembership LiteLLM_OrganizationMembership_budget_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_OrganizationMembership"
    ADD CONSTRAINT "LiteLLM_OrganizationMembership_budget_id_fkey" FOREIGN KEY (budget_id) REFERENCES public."LiteLLM_BudgetTable"(budget_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_OrganizationMembership LiteLLM_OrganizationMembership_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_OrganizationMembership"
    ADD CONSTRAINT "LiteLLM_OrganizationMembership_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public."LiteLLM_OrganizationTable"(organization_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: LiteLLM_OrganizationMembership LiteLLM_OrganizationMembership_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_OrganizationMembership"
    ADD CONSTRAINT "LiteLLM_OrganizationMembership_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public."LiteLLM_UserTable"(user_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: LiteLLM_OrganizationTable LiteLLM_OrganizationTable_budget_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_OrganizationTable"
    ADD CONSTRAINT "LiteLLM_OrganizationTable_budget_id_fkey" FOREIGN KEY (budget_id) REFERENCES public."LiteLLM_BudgetTable"(budget_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: LiteLLM_OrganizationTable LiteLLM_OrganizationTable_object_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_OrganizationTable"
    ADD CONSTRAINT "LiteLLM_OrganizationTable_object_permission_id_fkey" FOREIGN KEY (object_permission_id) REFERENCES public."LiteLLM_ObjectPermissionTable"(object_permission_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_TeamMembership LiteLLM_TeamMembership_budget_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_TeamMembership"
    ADD CONSTRAINT "LiteLLM_TeamMembership_budget_id_fkey" FOREIGN KEY (budget_id) REFERENCES public."LiteLLM_BudgetTable"(budget_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_TeamTable LiteLLM_TeamTable_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_TeamTable"
    ADD CONSTRAINT "LiteLLM_TeamTable_model_id_fkey" FOREIGN KEY (model_id) REFERENCES public."LiteLLM_ModelTable"(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_TeamTable LiteLLM_TeamTable_object_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_TeamTable"
    ADD CONSTRAINT "LiteLLM_TeamTable_object_permission_id_fkey" FOREIGN KEY (object_permission_id) REFERENCES public."LiteLLM_ObjectPermissionTable"(object_permission_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_TeamTable LiteLLM_TeamTable_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_TeamTable"
    ADD CONSTRAINT "LiteLLM_TeamTable_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public."LiteLLM_OrganizationTable"(organization_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_UserTable LiteLLM_UserTable_object_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_UserTable"
    ADD CONSTRAINT "LiteLLM_UserTable_object_permission_id_fkey" FOREIGN KEY (object_permission_id) REFERENCES public."LiteLLM_ObjectPermissionTable"(object_permission_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_UserTable LiteLLM_UserTable_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_UserTable"
    ADD CONSTRAINT "LiteLLM_UserTable_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public."LiteLLM_OrganizationTable"(organization_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_VerificationToken LiteLLM_VerificationToken_budget_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_VerificationToken"
    ADD CONSTRAINT "LiteLLM_VerificationToken_budget_id_fkey" FOREIGN KEY (budget_id) REFERENCES public."LiteLLM_BudgetTable"(budget_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_VerificationToken LiteLLM_VerificationToken_object_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_VerificationToken"
    ADD CONSTRAINT "LiteLLM_VerificationToken_object_permission_id_fkey" FOREIGN KEY (object_permission_id) REFERENCES public."LiteLLM_ObjectPermissionTable"(object_permission_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: LiteLLM_VerificationToken LiteLLM_VerificationToken_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."LiteLLM_VerificationToken"
    ADD CONSTRAINT "LiteLLM_VerificationToken_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public."LiteLLM_OrganizationTable"(organization_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

