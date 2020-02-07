BEGIN;
DROP MATERIALIZED VIEW tiddy.interactees;

DROP MATERIALIZED VIEW tiddy.image_index;

DROP MATERIALIZED VIEW tiddy.search_object_index;

DROP MATERIALIZED VIEW tiddy.tag_index;

CREATE MATERIALIZED VIEW tiddy.tag_index
TABLESPACE pg_default
AS
 SELECT sq.id,
    sq.name,
    sq.tag_type,
    sq.count
   FROM ( SELECT tags.id,
            tags.name,
            tags.tag_type,
            count(object_tags.object_id) AS count
           FROM tiddy.tags
             LEFT JOIN tiddy.object_tags ON tags.id = object_tags.tag_id
          GROUP BY tags.id) sq
  WHERE sq.count > 10
WITH DATA;

ALTER TABLE tiddy.tag_index
    OWNER TO postgres;


CREATE INDEX tag_exact_search
    ON tiddy.tag_index USING hash
    (name COLLATE pg_catalog."default")
    TABLESPACE pg_default;
CREATE INDEX tag_search_index
    ON tiddy.tag_index USING gist
    (name COLLATE pg_catalog."default" gist_trgm_ops)
    TABLESPACE pg_default;

CREATE MATERIALIZED VIEW tiddy.search_object_index
TABLESPACE pg_default
AS
 SELECT object.id,
    to_tsvector(string_agg(tags.name, ' '::text)) AS vec,
    to_tsvector('simple'::regconfig, string_agg(tags.name, ' '::text)) AS lit_vec,
    array_agg(tags.name) AS lit_arr,
    object.likes_count,
    object.created_at,
    object.embedding,
    jsonb_agg(jsonb_build_object('name', tags.name, 'type', tags.tag_type, 'count', tags.count, 'id', tags.id)) AS tags,
    object.type
   FROM tiddy.object
     LEFT JOIN (tiddy.object_tags
     JOIN tiddy.tag_index tags ON object_tags.tag_id = tags.id) ON object_tags.object_id = object.id
  GROUP BY object.id
WITH DATA;

ALTER TABLE tiddy.search_object_index
    OWNER TO postgres;

CREATE MATERIALIZED VIEW tiddy.image_index
TABLESPACE pg_default
AS
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
   FROM tiddy.search_object_index object_index
     JOIN tiddy.image ON object_index.id = image.object
  WHERE object_index.type = 'image'::tiddy.object_type AND image.serving_url IS NOT NULL
WITH DATA;

ALTER TABLE tiddy.image_index
    OWNER TO postgres;


CREATE INDEX img_index_date_index
    ON tiddy.image_index USING btree
    (created_at)
    TABLESPACE pg_default;
CREATE INDEX img_index_embedding_index
    ON tiddy.image_index USING gist
    (embedding)
    TABLESPACE pg_default;
CREATE INDEX img_index_id_index
    ON tiddy.image_index USING hash
    (id)
    TABLESPACE pg_default;
CREATE INDEX img_index_legacy_idx
    ON tiddy.image_index USING hash
    (legacy_id COLLATE pg_catalog."default")
    TABLESPACE pg_default;
CREATE INDEX img_index_likes_count
    ON tiddy.image_index USING btree
    (likes_count)
    TABLESPACE pg_default;
CREATE INDEX img_index_lit_index
    ON tiddy.image_index USING gin
    (lit_arr COLLATE pg_catalog."default")
    TABLESPACE pg_default;

CREATE MATERIALIZED VIEW tiddy.interactees
TABLESPACE pg_default
AS
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
   FROM ( SELECT gel_faves_weird.current_id,
            array_agg(gel_faves_weird.guid) AS users
           FROM tiddy.gel_faves_weird
          GROUP BY gel_faves_weird.current_id) sq
     RIGHT JOIN tiddy.image_index ON image_index.id = sq.current_id
WITH DATA;

ALTER TABLE tiddy.interactees
    OWNER TO postgres;


CREATE INDEX interactees_id_index
    ON tiddy.interactees USING btree
    (id)
    TABLESPACE pg_default;
COMMIT;
