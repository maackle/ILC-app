
DROP TABLE IF EXISTS :local_demography_table;

CREATE TABLE :local_demography_table AS
	SELECT * FROM :global_demography_table
	WHERE ST_Intersects(
		geom, 
		(select ST_Buffer(ST_Collect(geom), :buffer_radius) from :global_demography_table where substr(GID, 1, 5) IN :fips5_list)
	)
;


	-- WHERE
	-- 	SUBSTR(GEOID, 0, 5) IN 
	-- 		SELECT SUBSTR(GEOID, 0, 5) FROM :global_demography_table