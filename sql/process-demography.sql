BEGIN;

DROP TABLE IF EXISTS :occupation_table;
CREATE TABLE :occupation_table (
	gid			INT	PRIMARY KEY,
	management		FLOAT,
	service			FLOAT,
	office 			FLOAT,
	construction	FLOAT,
	manufacturing	FLOAT
);

INSERT INTO :occupation_table (gid, management, service, office, construction, manufacturing) 
	SELECT
		GID,
		SUM( density * MGMT )	AS management,
		SUM( density * SERVICE )	AS service,
		SUM( density * OFFICE )	AS office,
		SUM( density * CONST )	AS construction,
		SUM( density * PROD )	AS manufacturing
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
		) as raw
		 JOIN (
			SELECT 
				MGMT, SERVICE, OFFICE, CONST, PROD,
				geom as tract,
				ST_Area( geom ) as tract_area
			FROM :local_demography_table
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
	black 		FLOAT,
	asian 		FLOAT,
	multi 		FLOAT
);

INSERT INTO :race_table (gid, white, black, asian, multi) 
	SELECT
		GID,
		SUM( density * WHITE )	AS white,
		SUM( density * BLACK )	AS black,
		SUM( density * ASIAN )	AS asian,
		SUM( density * MULTI )	AS multi
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
		) as raw
		 JOIN (
			SELECT 
				WHITE, BLACK, ASIAN, MULTI,
				geom as tract,
				ST_Area( geom ) as tract_area
			FROM :local_demography_table
		) as census
		ON ST_Intersects( raw.circle_buffer, census.tract )
	)
	GROUP BY GID
;

END;