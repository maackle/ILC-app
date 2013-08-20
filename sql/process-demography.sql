BEGIN;

DROP TABLE IF EXISTS :occupation_table;
CREATE TABLE :occupation_table (
	gid			INT	PRIMARY KEY,
	management 		FLOAT,
	service			FLOAT,
	office			FLOAT,
	construction	FLOAT,
	production		FLOAT
);

DROP TABLE IF EXISTS :race_table;
CREATE TABLE :race_table (
	gid			INT	PRIMARY KEY,
	white 		FLOAT,
	black 		FLOAT,
	native 		FLOAT,
	asian 		FLOAT,
	islander 	FLOAT,
	other 		FLOAT,
	mixed 		FLOAT
);


INSERT INTO :occupation_table (gid, management, service, office, construction, production) 
	SELECT
		GID,
		SUM( density * HD01_VD03 )	AS management,
		SUM( density * HD01_VD04 )	AS service,
		SUM( density * HD01_VD05 )	AS office,
		SUM( density * HD01_VD06 )	AS construction,
		SUM( density * HD01_VD07 )	AS production
	FROM (
		SELECT 
			raw.GID,
			census.*,
			ST_Area( ST_Intersection( circle_buffer, census.tract ) ) / census.tract_area AS density
		FROM (
			SELECT
				GID,
				ST_Buffer( ST_Centroid( ST_Transform( geom, :equal_area_srid ) ), 1609*5 ) as circle_buffer
			FROM :raw_industrial_table
		) as raw
		LEFT JOIN (
			SELECT 
				HD01_VD03, HD01_VD04, HD01_VD05, HD01_VD06, HD01_VD07,
				geom as tract,
				ST_Area( geom ) as tract_area
			FROM :global_demography_table
		) as census
		ON ST_Intersects( raw.circle_buffer, census.tract )
	) as asdf
	GROUP BY GID
;


-- INSERT INTO :race_table (gid, white, black, native, asian, islander, other, mixed) 
-- 	SELECT
-- 		GID,
-- 		SUM( density * DP0080003 )	AS white,
-- 		SUM( density * DP0080004 )	AS black,
-- 		SUM( density * DP0080005 )	AS native,
-- 		SUM( density * DP0080006 )	AS asian,
-- 		SUM( density * DP0080014 )	AS islander,
-- 		SUM( density * DP0080019 )	AS other,
-- 		SUM( density * DP0080020 )	AS mixed
-- 	FROM (
-- 		SELECT 
-- 			raw.GID,
-- 			census.*,
-- 			ST_Area( ST_Intersection( circle_buffer, census.tract ) ) / census.tract_area AS density
-- 		FROM (
-- 			SELECT
-- 				GID,
-- 				ST_Buffer( ST_Centroid( ST_Transform ( geom, :equal_area_srid ) ), 1609 ) as circle_buffer
-- 			FROM :raw_industrial_table
-- 		) as raw
-- 		LEFT JOIN (
-- 			SELECT 
-- 				DP0080003, DP0080004, DP0080005, DP0080006, DP0080014, DP0080019, DP0080020,
-- 				geom as tract,
-- 				ST_Area( geom ) as tract_area
-- 			FROM :global_demography_table
-- 		) as census
-- 		ON ST_Intersects( raw.circle_buffer, census.tract )
-- 	) as asdf
-- 	GROUP BY GID
-- ;

END;