
global_data = {
	'census': None,	
}

meck = {
	'name': 'meck',
	'title': 'Mecklensburg County, NC',
	'vectors': {
		'industrial_parcels': 'industrial_parcels.shp',
		'converted_parcels': 'converted_parcels.shp',
	},
	'rasters': (
		{
			'name': 'corridors-wedges',
			'title': 'Corridors & Wedges',
			'format': 'png',
			'minzoom': 10,
			'maxzoom': 13,
		},
		# TODO ...
	),
}

"""
global/
	census.shp
	brownfields.shp

proj/
	meck/
		geom.shp
		project.py
		data/
			industrial_parcels.shp
			converted_parcels.shp

dist/
	meck/
		tiles/
			corridors-wedges/
				legend.png
				...data...
			planned-improvements/
				legend.png
				...data...
		features/
			industrial/
				1.geojson
				2.geojson
				...
			converted/
				1.geojson
				2.geojson
				...
"""