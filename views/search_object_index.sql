BEGIN;
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
COMMIT;
