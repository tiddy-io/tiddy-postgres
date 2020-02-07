BEGIN;
DROP MATERIALIZED VIEW tiddy.aug_faves;

CREATE MATERIALIZED VIEW tiddy.aug_faves
TABLESPACE pg_default
AS
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
                  WHERE user_counts.guid = gel_faves_weird_1.guid)) <= 100
          GROUP BY gel_faves_weird_1.current_id
        )
 SELECT gel_faves_weird.current_id,
    gel_faves_weird.guid,
    likers.users
   FROM tiddy.gel_faves_weird
     JOIN likers ON gel_faves_weird.current_id = likers.current_id
WITH DATA;

ALTER TABLE tiddy.aug_faves
    OWNER TO postgres;
COMMIT;
