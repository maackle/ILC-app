
DROP TABLE IF EXISTS :local_demography_table;

CREATE TABLE :local_demography_table AS
	SELECT * FROM :global_demography_table
	WHERE ST_Intersects(
		geom, 
		(
			select ST_Buffer(ST_Collect(geom), :buffer_radius) 
			from :global_demography_table 
			where substr(GEOID10, 1, 5) IN :fips_list
		)
	)
;

-- TODO: break this up into chunks, because it uses too much memory!