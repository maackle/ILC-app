BEGIN;

DROP TABLE IF EXISTS :occupation_table;
CREATE TABLE :occupation_table (
	gid			INT	PRIMARY KEY,
	manufacturing	FLOAT,
	construction	FLOAT
);

INSERT INTO :occupation_table (gid, manufacturing, construction) 
	SELECT
		GID,
		SUM( density * MNFCT )	AS manufacturing,
		SUM( density * CNSTRT )	AS construction
	FROM (
		SELECT 
			raw.GID,
			census.*,
			ST_Area( ST_Intersection( circle_buffer, census.tract ) ) / census.tract_area AS density
		FROM (
			SELECT
				GID,
				ST_Buffer( ST_Transform( ST_Centroid(geom), :equal_area_srid ), 1609*5 ) as circle_buffer
			FROM :raw_industrial_table
			LIMIT 10
		) as raw
		LEFT JOIN (
			SELECT 
				MNFCT, CNSTRT,
				geom as tract,
				ST_Area( geom ) as tract_area
			FROM :global_demography_table
		) as census
		ON ST_Intersects( raw.circle_buffer, census.tract )
	)
	GROUP BY GID
;

END;

BEGIN;

DROP TABLE IF EXISTS :race_table;
CREATE TABLE :race_table (
	gid			INT	PRIMARY KEY,
	white 		FLOAT,
	black 		FLOAT
);

INSERT INTO :race_table (gid, white, black) 
	SELECT
		GID,
		SUM( density * WHITE )	AS white,
		SUM( density * BLACK )	AS black
	FROM (
		SELECT 
			raw.GID,
			census.*,
			ST_Area( ST_Intersection( circle_buffer, census.tract ) ) / census.tract_area AS density
		FROM (
			SELECT
				GID,
				ST_Buffer( ST_Transform( ST_Centroid(geom), :equal_area_srid ), 1609 ) as circle_buffer
			FROM :raw_industrial_table
			LIMIT 10
		) as raw
		LEFT JOIN (
			SELECT 
				WHITE, BLACK,
				geom as tract,
				ST_Area( geom ) as tract_area
			FROM :global_demography_table
		) as census
		ON ST_Intersects( raw.circle_buffer, census.tract )
	)
	GROUP BY GID
;

END;