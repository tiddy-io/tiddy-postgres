--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.15
-- Dumped by pg_dump version 12.1

-- Started on 2020-02-06 20:18:58 PST

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
-- TOC entry 8 (class 2615 OID 17124)
-- Name: tiddy; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tiddy;


ALTER SCHEMA tiddy OWNER TO postgres;

--
-- TOC entry 759 (class 1247 OID 17129)
-- Name: feedback_value; Type: TYPE; Schema: tiddy; Owner: postgres
--

CREATE TYPE tiddy.feedback_value AS ENUM (
    'like',
    'dislike'
);


ALTER TYPE tiddy.feedback_value OWNER TO postgres;

--
-- TOC entry 762 (class 1247 OID 17134)
-- Name: object_type; Type: TYPE; Schema: tiddy; Owner: postgres
--

CREATE TYPE tiddy.object_type AS ENUM (
    'image',
    'image_series',
    'audio',
    'text'
);


ALTER TYPE tiddy.object_type OWNER TO postgres;

--
-- TOC entry 711 (class 1247 OID 43232)
-- Name: tag_type; Type: TYPE; Schema: tiddy; Owner: postgres
--

CREATE TYPE tiddy.tag_type AS ENUM (
    'artist',
    'character',
    'source_material',
    'meta',
    'description'
);


ALTER TYPE tiddy.tag_type OWNER TO postgres;

SET default_tablespace = '';

--
-- TOC entry 210 (class 1259 OID 2042939)
-- Name: accounts; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.accounts (
    username text NOT NULL,
    pwd_hash text NOT NULL
);


ALTER TABLE tiddy.accounts OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 68981468)
-- Name: activity; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.activity (
    "user" text,
    object integer,
    label text,
    value jsonb,
    "timestamp" timestamp without time zone
);


ALTER TABLE tiddy.activity OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 71435963)
-- Name: gel_faves_weird; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.gel_faves_weird (
    mongo_id text,
    gpid integer,
    guid integer,
    tags text[],
    current_id integer
);


ALTER TABLE tiddy.gel_faves_weird OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 17529)
-- Name: feedback; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.feedback (
    "user" character varying(128) NOT NULL,
    object integer NOT NULL,
    value tiddy.feedback_value NOT NULL,
    "time" timestamp without time zone
);


ALTER TABLE tiddy.feedback OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 43292)
-- Name: object_tags; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.object_tags (
    object_id integer NOT NULL,
    tag_id integer NOT NULL
);


ALTER TABLE tiddy.object_tags OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 110461)
-- Name: _deprecated_rich_tags; Type: VIEW; Schema: tiddy; Owner: postgres
--

CREATE VIEW tiddy._deprecated_rich_tags AS
SELECT
    NULL::integer AS id,
    NULL::text AS name,
    NULL::tiddy.tag_type AS tag_type,
    NULL::bigint AS count;


ALTER TABLE tiddy._deprecated_rich_tags OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 43284)
-- Name: _scrape_tag_types; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy._scrape_tag_types (
    name character varying,
    type_num integer
);


ALTER TABLE tiddy._scrape_tag_types OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 71436659)
-- Name: aug_faves; Type: MATERIALIZED VIEW; Schema: tiddy; Owner: postgres
--

CREATE MATERIALIZED VIEW tiddy.aug_faves AS
 WITH user_counts AS (
         SELECT gel_faves_weird_2.guid,
            count(gel_faves_weird_2.current_id) AS ct
           FROM tiddy.gel_faves_weird gel_faves_weird_2
          GROUP BY gel_faves_weird_2.guid
        ), likers AS (
         SELECT gel_faves_weird_1.current_id,
            array_agg(gel_faves_weird_1.guid) AS users
           FROM tiddy.gel_faves_weird gel_faves_weird_1
          WHERE (( SELECT user_counts.ct
                   FROM user_counts
                  WHERE (user_counts.guid = gel_faves_weird_1.guid)) <= 100)
          GROUP BY gel_faves_weird_1.current_id
        )
 SELECT gel_faves_weird.current_id,
    gel_faves_weird.guid,
    likers.users
   FROM (tiddy.gel_faves_weird
     JOIN likers ON ((gel_faves_weird.current_id = likers.current_id)))
  WITH NO DATA;


ALTER TABLE tiddy.aug_faves OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 71436623)
-- Name: embedding_upload; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.embedding_upload (
    id integer NOT NULL,
    embedding public.cube NOT NULL,
    bias double precision NOT NULL,
    source text NOT NULL
);


ALTER TABLE tiddy.embedding_upload OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 110557)
-- Name: empty_table; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.empty_table (
);


ALTER TABLE tiddy.empty_table OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 8328926)
-- Name: gel_faves; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.gel_faves (
    mongo_id text,
    gpid numeric,
    guid integer,
    tags text[],
    current_id integer
);


ALTER TABLE tiddy.gel_faves OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 71435903)
-- Name: gel_faves_aug; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.gel_faves_aug (
    mongo_id text,
    gpid integer,
    guid integer,
    tags text[],
    current_id integer
);


ALTER TABLE tiddy.gel_faves_aug OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 17169)
-- Name: image; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.image (
    id integer NOT NULL,
    legacy_id text,
    object integer,
    height integer NOT NULL,
    width integer NOT NULL,
    image_source integer,
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    compressed boolean,
    animated boolean,
    serving_url text,
    us_public boolean,
    nearline boolean
);


ALTER TABLE tiddy.image OWNER TO postgres;

--
-- TOC entry 200 (class 1259 OID 17167)
-- Name: image_id_seq; Type: SEQUENCE; Schema: tiddy; Owner: postgres
--

CREATE SEQUENCE tiddy.image_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tiddy.image_id_seq OWNER TO postgres;

--
-- TOC entry 3087 (class 0 OID 0)
-- Dependencies: 200
-- Name: image_id_seq; Type: SEQUENCE OWNED BY; Schema: tiddy; Owner: postgres
--

ALTER SEQUENCE tiddy.image_id_seq OWNED BY tiddy.image.id;


--
-- TOC entry 199 (class 1259 OID 17158)
-- Name: image_source; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.image_source (
    id integer NOT NULL,
    source_type text NOT NULL,
    publishable boolean,
    json json,
    guid integer
);


ALTER TABLE tiddy.image_source OWNER TO postgres;

--
-- TOC entry 198 (class 1259 OID 17156)
-- Name: image_source_id_seq; Type: SEQUENCE; Schema: tiddy; Owner: postgres
--

CREATE SEQUENCE tiddy.image_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tiddy.image_source_id_seq OWNER TO postgres;

--
-- TOC entry 3088 (class 0 OID 0)
-- Dependencies: 198
-- Name: image_source_id_seq; Type: SEQUENCE OWNED BY; Schema: tiddy; Owner: postgres
--

ALTER SEQUENCE tiddy.image_source_id_seq OWNED BY tiddy.image_source.id;


--
-- TOC entry 213 (class 1259 OID 69346125)
-- Name: img_index; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.img_index (
    id integer NOT NULL,
    vec tsvector,
    lit_vec tsvector,
    lit_arr text[],
    embedding public.cube,
    likes_count integer,
    created_at timestamp without time zone,
    compressed boolean,
    animated boolean,
    width integer,
    height integer,
    legacy_id text,
    serving_url text,
    tags jsonb
);


ALTER TABLE tiddy.img_index OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 72627768)
-- Name: interactors; Type: MATERIALIZED VIEW; Schema: tiddy; Owner: postgres
--

CREATE MATERIALIZED VIEW tiddy.interactors AS
 SELECT gel_faves_weird.guid,
    count(gel_faves_weird.current_id) AS item_count,
    array_agg(gel_faves_weird.current_id) AS items
   FROM tiddy.gel_faves_weird
  GROUP BY gel_faves_weird.guid
  WITH NO DATA;


ALTER TABLE tiddy.interactors OWNER TO postgres;

--
-- TOC entry 197 (class 1259 OID 17145)
-- Name: object; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.object (
    id integer NOT NULL,
    type tiddy.object_type NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    _deprecated_tags text[],
    likes_count integer DEFAULT 0 NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    embedding public.cube,
    short_embedding public.cube,
    mid_embedding public.cube
);


ALTER TABLE tiddy.object OWNER TO postgres;

--
-- TOC entry 196 (class 1259 OID 17143)
-- Name: object_id_seq; Type: SEQUENCE; Schema: tiddy; Owner: postgres
--

CREATE SEQUENCE tiddy.object_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tiddy.object_id_seq OWNER TO postgres;

--
-- TOC entry 3089 (class 0 OID 0)
-- Dependencies: 196
-- Name: object_id_seq; Type: SEQUENCE OWNED BY; Schema: tiddy; Owner: postgres
--

ALTER SEQUENCE tiddy.object_id_seq OWNED BY tiddy.object.id;


--
-- TOC entry 204 (class 1259 OID 43245)
-- Name: tags; Type: TABLE; Schema: tiddy; Owner: postgres
--

CREATE TABLE tiddy.tags (
    id integer NOT NULL,
    name text NOT NULL,
    tag_type tiddy.tag_type
);


ALTER TABLE tiddy.tags OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 43243)
-- Name: tags_id_seq; Type: SEQUENCE; Schema: tiddy; Owner: postgres
--

CREATE SEQUENCE tiddy.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tiddy.tags_id_seq OWNER TO postgres;

--
-- TOC entry 3090 (class 0 OID 0)
-- Dependencies: 203
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: tiddy; Owner: postgres
--

ALTER SEQUENCE tiddy.tags_id_seq OWNED BY tiddy.tags.id;


--
-- TOC entry 2897 (class 2604 OID 17172)
-- Name: image id; Type: DEFAULT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.image ALTER COLUMN id SET DEFAULT nextval('tiddy.image_id_seq'::regclass);


--
-- TOC entry 2896 (class 2604 OID 17161)
-- Name: image_source id; Type: DEFAULT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.image_source ALTER COLUMN id SET DEFAULT nextval('tiddy.image_source_id_seq'::regclass);


--
-- TOC entry 2892 (class 2604 OID 17148)
-- Name: object id; Type: DEFAULT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.object ALTER COLUMN id SET DEFAULT nextval('tiddy.object_id_seq'::regclass);


--
-- TOC entry 2900 (class 2604 OID 43248)
-- Name: tags id; Type: DEFAULT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.tags ALTER COLUMN id SET DEFAULT nextval('tiddy.tags_id_seq'::regclass);


--
-- TOC entry 2919 (class 2606 OID 43253)
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- TOC entry 208 (class 1259 OID 110539)
-- Name: tag_index; Type: MATERIALIZED VIEW; Schema: tiddy; Owner: postgres
--

CREATE MATERIALIZED VIEW tiddy.tag_index AS
 SELECT sq.id,
    sq.name,
    sq.tag_type,
    sq.count
   FROM ( SELECT tags.id,
            tags.name,
            tags.tag_type,
            count(object_tags.object_id) AS count
           FROM (tiddy.tags
             LEFT JOIN tiddy.object_tags ON ((tags.id = object_tags.tag_id)))
          GROUP BY tags.id) sq
  WHERE (sq.count > 10)
  WITH NO DATA;


ALTER TABLE tiddy.tag_index OWNER TO postgres;

--
-- TOC entry 2904 (class 2606 OID 17155)
-- Name: object object_pkey; Type: CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.object
    ADD CONSTRAINT object_pkey PRIMARY KEY (id);


--
-- TOC entry 214 (class 1259 OID 69382453)
-- Name: search_object_index; Type: MATERIALIZED VIEW; Schema: tiddy; Owner: postgres
--

CREATE MATERIALIZED VIEW tiddy.search_object_index AS
 SELECT object.id,
    to_tsvector(string_agg(tags.name, ' '::text)) AS vec,
    to_tsvector('simple'::regconfig, string_agg(tags.name, ' '::text)) AS lit_vec,
    array_agg(tags.name) AS lit_arr,
    object.likes_count,
    object.created_at,
    object.embedding,
    jsonb_agg(jsonb_build_object('name', tags.name, 'type', tags.tag_type, 'count', tags.count, 'id', tags.id)) AS tags,
    object.type
   FROM (tiddy.object
     LEFT JOIN (tiddy.object_tags
     JOIN tiddy.tag_index tags ON ((object_tags.tag_id = tags.id))) ON ((object_tags.object_id = object.id)))
  GROUP BY object.id
  WITH NO DATA;


ALTER TABLE tiddy.search_object_index OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 70341775)
-- Name: image_index; Type: MATERIALIZED VIEW; Schema: tiddy; Owner: postgres
--

CREATE MATERIALIZED VIEW tiddy.image_index AS
 SELECT object_index.id,
    object_index.vec,
    object_index.lit_vec,
    object_index.lit_arr,
    object_index.embedding,
    object_index.likes_count,
    object_index.created_at,
    object_index.tags,
    image.compressed,
    image.animated,
    image.width,
    image.height,
    image.legacy_id,
    image.serving_url
   FROM (tiddy.search_object_index object_index
     JOIN tiddy.image ON ((object_index.id = image.object)))
  WHERE ((object_index.type = 'image'::tiddy.object_type) AND (image.serving_url IS NOT NULL))
  WITH NO DATA;


ALTER TABLE tiddy.image_index OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 72630904)
-- Name: interactees; Type: MATERIALIZED VIEW; Schema: tiddy; Owner: postgres
--

CREATE MATERIALIZED VIEW tiddy.interactees AS
 SELECT image_index.id,
    image_index.likes_count,
    image_index.created_at,
    image_index.lit_arr,
    image_index.compressed,
    image_index.animated,
    image_index.width,
    image_index.height,
    image_index.legacy_id,
    image_index.serving_url,
    sq.users
   FROM (( SELECT gel_faves_weird.current_id,
            array_agg(gel_faves_weird.guid) AS users
           FROM tiddy.gel_faves_weird
          GROUP BY gel_faves_weird.current_id) sq
     RIGHT JOIN tiddy.image_index ON ((image_index.id = sq.current_id)))
  WITH NO DATA;


ALTER TABLE tiddy.interactees OWNER TO postgres;

--
-- TOC entry 2929 (class 2606 OID 2042946)
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (username);


--
-- TOC entry 2944 (class 2606 OID 71436640)
-- Name: embedding_upload embedding_upload_pkey; Type: CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.embedding_upload
    ADD CONSTRAINT embedding_upload_pkey PRIMARY KEY (id, source);


--
-- TOC entry 2914 (class 2606 OID 17533)
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY ("user", object);


--
-- TOC entry 2911 (class 2606 OID 17177)
-- Name: image image_pkey; Type: CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.image
    ADD CONSTRAINT image_pkey PRIMARY KEY (id);


--
-- TOC entry 2908 (class 2606 OID 17166)
-- Name: image_source image_source_pkey; Type: CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.image_source
    ADD CONSTRAINT image_source_pkey PRIMARY KEY (id);


--
-- TOC entry 2931 (class 2606 OID 69346211)
-- Name: img_index img_index_pkey; Type: CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.img_index
    ADD CONSTRAINT img_index_pkey PRIMARY KEY (id);


--
-- TOC entry 2924 (class 2606 OID 43296)
-- Name: object_tags object_tag_pkey; Type: CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.object_tags
    ADD CONSTRAINT object_tag_pkey PRIMARY KEY (object_id, tag_id);


--
-- TOC entry 2927 (class 1259 OID 2042947)
-- Name: account_user_lookup; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX account_user_lookup ON tiddy.accounts USING hash (username);


--
-- TOC entry 2941 (class 1259 OID 71436635)
-- Name: embedding_id_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX embedding_id_index ON tiddy.embedding_upload USING btree (id);


--
-- TOC entry 2942 (class 1259 OID 71436634)
-- Name: embedding_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX embedding_index ON tiddy.embedding_upload USING gist (embedding);


--
-- TOC entry 2912 (class 1259 OID 451103)
-- Name: feedback_id_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX feedback_id_index ON tiddy.feedback USING hash (object);


--
-- TOC entry 2915 (class 1259 OID 5420749)
-- Name: feedback_search_test; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX feedback_search_test ON tiddy.feedback USING btree (value, "user");


--
-- TOC entry 2916 (class 1259 OID 914617)
-- Name: feedback_user_only; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX feedback_user_only ON tiddy.feedback USING hash ("user");


--
-- TOC entry 2917 (class 1259 OID 451102)
-- Name: feedback_user_type_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX feedback_user_type_index ON tiddy.feedback USING btree ("user", value);


--
-- TOC entry 2939 (class 1259 OID 71436622)
-- Name: gel_faves_weird_cid_idx; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX gel_faves_weird_cid_idx ON tiddy.gel_faves_weird USING btree (current_id);


--
-- TOC entry 2940 (class 1259 OID 71435985)
-- Name: gel_faves_weird_gpid_idx; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX gel_faves_weird_gpid_idx ON tiddy.gel_faves_weird USING btree (gpid);


--
-- TOC entry 2909 (class 1259 OID 4005578)
-- Name: image_id_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX image_id_index ON tiddy.image USING hash (id);


--
-- TOC entry 2906 (class 1259 OID 68981475)
-- Name: image_source_guid_idx; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX image_source_guid_idx ON tiddy.image_source USING hash (guid);


--
-- TOC entry 2932 (class 1259 OID 71435873)
-- Name: img_index_date_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX img_index_date_index ON tiddy.image_index USING btree (created_at);


--
-- TOC entry 2933 (class 1259 OID 71435874)
-- Name: img_index_embedding_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX img_index_embedding_index ON tiddy.image_index USING gist (embedding);


--
-- TOC entry 2934 (class 1259 OID 71435875)
-- Name: img_index_id_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX img_index_id_index ON tiddy.image_index USING hash (id);


--
-- TOC entry 2935 (class 1259 OID 71435876)
-- Name: img_index_legacy_idx; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX img_index_legacy_idx ON tiddy.image_index USING hash (legacy_id);


--
-- TOC entry 2936 (class 1259 OID 71435877)
-- Name: img_index_likes_count; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX img_index_likes_count ON tiddy.image_index USING btree (likes_count);


--
-- TOC entry 2937 (class 1259 OID 71435878)
-- Name: img_index_lit_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX img_index_lit_index ON tiddy.image_index USING gin (lit_arr);


--
-- TOC entry 2946 (class 1259 OID 72631003)
-- Name: interactees_id_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX interactees_id_index ON tiddy.interactees USING btree (id);


--
-- TOC entry 2945 (class 1259 OID 72630798)
-- Name: interactors_guid_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX interactors_guid_index ON tiddy.interactors USING btree (guid);


--
-- TOC entry 2920 (class 1259 OID 43307)
-- Name: obj_tag_id_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX obj_tag_id_index ON tiddy.object_tags USING hash (object_id);


--
-- TOC entry 2921 (class 1259 OID 72631012)
-- Name: obj_tag_tag_btree; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX obj_tag_tag_btree ON tiddy.object_tags USING btree (tag_id);


--
-- TOC entry 2922 (class 1259 OID 110465)
-- Name: obj_tag_tag_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX obj_tag_tag_index ON tiddy.object_tags USING hash (tag_id);


--
-- TOC entry 2901 (class 1259 OID 7279367)
-- Name: object_knn_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX object_knn_index ON tiddy.object USING gist (embedding);


--
-- TOC entry 2902 (class 1259 OID 7279409)
-- Name: object_mid_knn_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX object_mid_knn_index ON tiddy.object USING gist (mid_embedding);


--
-- TOC entry 2905 (class 1259 OID 7279366)
-- Name: object_short_knn_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX object_short_knn_index ON tiddy.object USING gist (short_embedding);


--
-- TOC entry 2938 (class 1259 OID 71435993)
-- Name: pid_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX pid_index ON tiddy.gel_faves_aug USING btree (gpid);


--
-- TOC entry 2925 (class 1259 OID 110556)
-- Name: tag_exact_search; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX tag_exact_search ON tiddy.tag_index USING hash (name);


--
-- TOC entry 2926 (class 1259 OID 110548)
-- Name: tag_search_index; Type: INDEX; Schema: tiddy; Owner: postgres
--

CREATE INDEX tag_search_index ON tiddy.tag_index USING gist (name public.gist_trgm_ops);


--
-- TOC entry 3069 (class 2618 OID 110464)
-- Name: _deprecated_rich_tags _RETURN; Type: RULE; Schema: tiddy; Owner: postgres
--

CREATE OR REPLACE VIEW tiddy._deprecated_rich_tags WITH (security_barrier='false') AS
 SELECT tags.id,
    tags.name,
    tags.tag_type,
    count(object_tags.object_id) AS count
   FROM (tiddy.tags
     LEFT JOIN tiddy.object_tags ON ((tags.id = object_tags.tag_id)))
  GROUP BY tags.id;


--
-- TOC entry 2949 (class 2606 OID 43174)
-- Name: feedback feedback_object_fkey; Type: FK CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.feedback
    ADD CONSTRAINT feedback_object_fkey FOREIGN KEY (object) REFERENCES tiddy.object(id) ON DELETE CASCADE;


--
-- TOC entry 2948 (class 2606 OID 17183)
-- Name: image image_image_source_fkey; Type: FK CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.image
    ADD CONSTRAINT image_image_source_fkey FOREIGN KEY (image_source) REFERENCES tiddy.image_source(id);


--
-- TOC entry 2947 (class 2606 OID 17178)
-- Name: image image_object_fkey; Type: FK CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.image
    ADD CONSTRAINT image_object_fkey FOREIGN KEY (object) REFERENCES tiddy.object(id);


--
-- TOC entry 2950 (class 2606 OID 43297)
-- Name: object_tags object_id_fkey; Type: FK CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.object_tags
    ADD CONSTRAINT object_id_fkey FOREIGN KEY (object_id) REFERENCES tiddy.object(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2951 (class 2606 OID 43302)
-- Name: object_tags tag_id_fkey; Type: FK CONSTRAINT; Schema: tiddy; Owner: postgres
--

ALTER TABLE ONLY tiddy.object_tags
    ADD CONSTRAINT tag_id_fkey FOREIGN KEY (tag_id) REFERENCES tiddy.tags(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2020-02-06 20:19:07 PST

--
-- PostgreSQL database dump complete
--

