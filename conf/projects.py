import os

from conf import settings
from util import *


class ProjectDefinition(object):

    SRID=settings.GEOGRAPHIC_SRID

    def __unicode__(self):
        return '<ProjectDefinition "{0}">'.format(self.title)

    def __str__(self):
        return unicode(self)

    def __init__(self, name, title, industrial_parcels, demography, converted_parcels_shapefile, raster_layers, fips_list):
        self.name = name
        self.title = title
        self.demography = demography
        self.industrial_parcels = industrial_parcels
        self.converted_parcels_shapefile = converted_parcels_shapefile
        self.raster_layers = raster_layers
        self.fips_list = fips_list

    def raw_data_dir(self, path=''):
        return os.path.join(settings.RAW_DATA_DIR, self.name, path)

    def app_data_dir(self, path=''):
        return os.path.join(settings.APP_DATA_DIR, self.name, path)

    # def probabilty_names(self):
    #     return [p['name'] for p in self.industrial_parcels['probability_categories']]

    @property
    def raw_industrial_table(self):
        return '_R_' + self.name + '_industrial'

    @property
    def raw_brownfields_table(self):
        return '_R_' + self.name + '_brownfields'

    @property
    def raw_converted_table(self):
        return '_R_' + self.name + '_converted'

    @property
    def occupation_table(self):
        return self.name + '_occupation'

    @property
    def race_table(self):
        return self.name + '_race'

    @property
    def industrial_table(self):
        return self.name + '_industrial'

    @property
    def raw_demography_table(self):
        return '_R_' + self.name + '_demography'

    def load_shapefiles(self):
        load_shapefile(self.raw_industrial_table, self.industrial_parcels['shapefile'], self.SRID)
        load_shapefile(self.raw_converted_table, self.converted_parcels_shapefile, self.SRID)


demography_race_fields = {
    'MGMT': 'management',
    'SERVICE': 'service',
    'OFFICE': 'office',
    'CONST': 'construction',
    'PROD': 'manufacturing',
}

meck = ProjectDefinition(
    name='meck',
    title='Mecklenburg County, North Carolina',
    converted_parcels_shapefile='meck_rawdata/alreadyconverted_m_P',
    industrial_parcels={
        'shapefile': 'meck_rawdata/still_industrial_m_P',
        'probability_categories': (
            {
                'rawname': 'pcnv_l',
                'name': 'risk_main',
                'title': 'Probability of Conversion to Industrial'
            },
            {
                'rawname': 'pcnv_r',
                'name': 'risk_res',
                'title': 'Probability of Conversion to Industrial from Residential'
            },
            {
                'rawname': 'pcnv_c',
                'name': 'risk_com',
                'title': 'Probability of Conversion to Industrial from Commercial'
            },
        ),
    },
    demography=settings.demography_categories,
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
    fips_list=('51117', '37119')
)


cook = ProjectDefinition(
    name='cook',
    title='Cook County, Illinois',
    industrial_parcels={
        'shapefile': 'cook_rawdata/cook_still_industrial',
        'probability_categories': (
            {
                'rawname': 'PCnv_',
                'name': 'risk_main',
                'title': 'Probability of Conversion to Industrial'
            },
        ),
    },
    demography=settings.demography_categories,
    converted_parcels_shapefile='cook_rawdata/cook_alreadyconverted',
    raster_layers=(),
    fips_list=('17031',)
)

projects = set((
    meck, cook,
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