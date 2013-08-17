from conf import settings
import os

global_data = {
	'brownfields': 'brownfields/GEODATA_Featureclass_MAR2013',
	'census': 'refwintroductions/Mecklenburg_CensusTracts',
	'demography': 'census/Occupation_race',
}

class ProjectDefinition(object):

	def __unicode__(self):
		return '<ProjectDefinition "{0}">'.format(self.title)

	def __str__(self):
		return unicode(self)

	def __init__(self, name, title, industrial_parcels_shp, converted_parcels_shp, raster_layers):
		self.name = name
		self.title = title
		self.industrial_parcels_shp = industrial_parcels_shp
		self.converted_parcels_shp = converted_parcels_shp
		self.raster_layers = raster_layers

	@property
	def raw_data_dir(self, path=''):
		return os.path.join(settings.RAW_DATA_DIR, self.name, path)

	@property
	def app_data_dir(self, path=''):
		return os.path.join(settings.APP_DATA_DIR, self.name, path)


meck = ProjectDefinition(
	name='meck',
	title='Mecklenburg County, NC',
	industrial_parcels_shp='still_industrial/still_industrial',
	converted_parcels_shp='alreadyconverted/alreadyconverted',
	raster_layers=(
		{
			'name': 'corridors-wedges',
			'title': 'Corridors & Wedges',
			'format': 'png',
			'minzoom': 10,
			'maxzoom': 13,
		},
		# TODO ...
	),
)

projects = set((
	meck,
))

# meck = {
# 	'name': 'meck',
# 	'title': 'Mecklenburg County, NC',
# 	'vectors': {
# 		'industrial_parcels': 'still_industrial/still_industrial.shp',
# 		'converted_parcels': 'alreadyconverted/alreadyconverted.shp',
# 	},
# 	'rasters': (
# 		{
# 			'name': 'corridors-wedges',
# 			'title': 'Corridors & Wedges',
# 			'format': 'png',
# 			'minzoom': 10,
# 			'maxzoom': 13,
# 		},
# 		# TODO ...
# 	),
# }


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