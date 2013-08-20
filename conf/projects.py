import os

from conf import settings
from util import *


global_datasets = {
    # settings.BROWNFIELDS_TABLE: 'brownfields/GEODATA_Featureclass_MAR2013',
    # 'census_tracts': {
    #     'table': settings.CENSUS_TABLE,
    #     'path': 'census_tracts/Mecklenburg_CensusTracts',
    #     'srid': settings.GEOGRAPHIC_SRID,
    # },
    'demography': {
        'table': settings.DEMOGRAPHY_TABLE,
        'path': 'demography/demography_meck_and_cook',
        'srid': settings.EQUAL_AREA_SRID,
    },
}

class ProjectDefinition(object):

    SRID=settings.GEOGRAPHIC_SRID

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

    @property
    def raw_industrial_table(self):
        return '_R_' + self.name + '_industrial'

    @property
    def raw_converted_table(self):
        return '_R_' + self.name + '_converted'

    @property
    def occupation_table(self):
        return self.name + '_occupation'

    @property
    def race_table(self):
        return self.name + '_race'

    def load_shapefiles(self):
        load_shapefile(self.raw_industrial_table, self.industrial_parcels_shp, self.SRID)
        load_shapefile(self.raw_converted_table, self.converted_parcels_shp, self.SRID)


meck = ProjectDefinition(
    name='meck',
    title='Mecklenburg County, NC',
    industrial_parcels_shp='still_industrial/meck-4326',
    converted_parcels_shp='alreadyconverted/meck-4326',
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
#   'name': 'meck',
#   'title': 'Mecklenburg County, NC',
#   'vectors': {
#       'industrial_parcels': 'still_industrial/still_industrial.shp',
#       'converted_parcels': 'alreadyconverted/alreadyconverted.shp',
#   },
#   'rasters': (
#       {
#           'name': 'corridors-wedges',
#           'title': 'Corridors & Wedges',
#           'format': 'png',
#           'minzoom': 10,
#           'maxzoom': 13,
#       },
#       # TODO ...
#   ),
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