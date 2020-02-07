BEGIN;
DROP MATERIALIZED VIEW tiddy.interactors;

CREATE MATERIALIZED VIEW tiddy.interactors
TABLESPACE pg_default
AS
 SELECT gel_faves_weird.guid,
    count(gel_faves_weird.current_id) AS item_count,
    array_agg(gel_faves_weird.current_id) AS items
   FROM tiddy.gel_faves_weird
  GROUP BY gel_faves_weird.guid
WITH DATA;

ALTER TABLE tiddy.interactors
    OWNER TO postgres;


CREATE INDEX interactors_guid_index
    ON tiddy.interactors USING btree
    (guid)
    TABLESPACE pg_default;
COMMIT;
