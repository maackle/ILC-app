
DROP TABLE IF EXISTS :table;
CREATE TABLE :table (
	gid			 		INT	PRIMARY KEY,
	naics				VARCHAR(6),

	:probability_name_with_type_list

	size_metric 		FLOAT
	-- geom				geometry(MultiPolygon, :geog_srid)
);

SELECT AddGeometryColumn(':table', 'geom', :geog_srid, 'MultiPolygon', 'XY');

INSERT INTO :table (
		gid, naics,
		:probability_name_list
		size_metric,
		geom
	)
	SELECT 
-- proxy (same values as raw)
		raw.ROWID, naics,

-- risk values
		:probability_rawname_list

-- size metric
		SQRT( ST_Area( geom ) ),

-- geometry
		geom

	FROM :rawtable AS raw
;

SELECT COUNT(gid) FROM :table; -- just to display total
