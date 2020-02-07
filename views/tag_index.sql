BEGIN;
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

COMMIT;
